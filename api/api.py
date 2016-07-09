import os
import sys
import inspect
import json
import argparse
import requests
import time
from flask import Flask, render_template, request, Response

currentdir = os.path.dirname(
    os.path.abspath(inspect.getfile(inspect.currentframe()))
)
parentdir = os.path.dirname(currentdir)
sys.path.insert(0, parentdir)

from lib.candidate_finders import PageviewCandidateFinder, MorelikeCandidateFinder, DeepCandidateFinder
from lib.embedding import WikiEmbedding
from lib.filters import apply_filters_chunkwise
from lib.pageviews import PageviewGetter

parser = argparse.ArgumentParser()
parser.add_argument(
    '--debug', required=False, action='store_true',
    help='run in debug mode'
)
args = parser.parse_args()

app = Flask(__name__)
app.debug = args.debug

language_pairs = requests.get('https://cxserver.wikimedia.org/v1/languagepairs').json()
embedding_path = os.path.join(currentdir, '../data/2016-03-01_2016-03-07_wikidata_100') #test_embedding

finder_map = {
    'morelike': MorelikeCandidateFinder(),
    'mostpopular': PageviewCandidateFinder(),
    'deep': DeepCandidateFinder(WikiEmbedding(embedding_path))
}


def json_response(dat):
    resp = Response(response=json.dumps(dat),
                    status=200,
                    mimetype='application/json')
    return resp


@app.route('/')
def home():
    s = request.args.get('s')
    t = request.args.get('t')
    seed = request.args.get('seed')
    return render_template(
        'index.html',
        language_pairs=json.dumps(language_pairs),
        s=s,
        t=t,
        seed=seed,
    )


@app.route('/api')
def get_recommendations():

    t1 = time.time()
    args = parse_args(request)

    if args['s'] not in language_pairs['source']:
        return json_response({'error': "Invalid Language"})


    recs = recommend(
        args['s'],
        args['finder'],
        seed = args['article'],
        n_recs = args['n'],
        pageviews = args['pageviews']
    )

    if len(recs) == 0:
        msg = 'Sorry, failed to get recommendations'
        return json_response({'error': msg})

    t2 = time.time()
    print('Total:', t2-t1)

    return json_response({'articles': recs})


def parse_args(request):
    """
    Parse api query parameters 
    """
    n = request.args.get('n')
    try:
        n = min(int(n), 24)
    except:
        n = 12

    # Get search algorithm

    if not request.args.get('article'):
        search = 'mostpopular'
    else:
        search = request.args.get('search')
        if search not in ('morelike', 'deep'):
            search = 'deep'
    finder = finder_map[search]
  

    # determine if client wants pageviews
    pageviews = request.args.get('pageviews')
    if pageviews == 'false':
        pageviews = False
    else:
        pageviews = True


    args = {
                's': request.args.get('s'),
                'article': request.args.get('article', ''),
                'n': n,
                'search' : search,
                'finder': finder,
                'pageviews': pageviews,
            }

    return args


def recommend(s, finder, seed = None, n_recs = 10, pageviews = True):
    """
    1. Use finder to select a set of candidate articles
    2. Filter out candidates that are not missing, are disambiguation pages, etc
    3. get pageview info for each passing candidate if desired
    """

    recs = []
    for seed in seed.split('|'):
        recs += finder.get_candidates(s, seed, 2*n_recs)
    recs = sorted(recs, key = lambda x: x.rank)

    recs = apply_filters_chunkwise(s, None, recs, n_recs)

    if pageviews:
        recs = PageviewGetter().get(s, recs)

    recs = sorted(recs, key = lambda x: x.rank)
    return [{'title': r.title, 'pageviews':r.pageviews, 'wikidata_id': r.wikidata_id} for r in recs]


@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE')
    return response


if __name__ == '__main__':
    app.run(host='0.0.0.0')