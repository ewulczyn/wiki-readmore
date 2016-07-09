import requests
import random
from datetime import datetime
from dateutil import relativedelta
from lib.embedding import WikiEmbedding, items_to_titles, titles_to_items
from lib.utils import Article, thread_function, chunk_list


class CandidateFinder():
    """
    CandidateFinder interface
    """
    def get_candidates(self, s, seed, n):
        """
        get list candidate source language articles
        using seed (optional)
        """
        return []


class PageviewCandidateFinder():
    """
    Utility Class for getting a list of the  most 
    popular articles in a source  Wikipedia.
    """
    def query_pageviews(self, s):
        """
        Query pageview API and parse results
        """
        dt = (datetime.utcnow() - relativedelta.relativedelta(days=2)).strftime('%Y/%m/%d')
        query = "https://wikimedia.org/api/rest_v1/metrics/pageviews/top/%s.wikipedia/all-access/%s" % (s, dt)
        data =  requests.get(query).json()
        article_pv_tuples = []

        try:
            for d in data['items'][0]['articles']:
                article_pv_tuples.append((d['article'], d['views']))
        except:
            print("Could not get most popular articles for %s from pageview API. Try using a seed article." % s)

        return article_pv_tuples


    def get_candidates(self, s, seed, n):
        """
        Wrap top articles in a list of Article objects
        """
        articles = []
        article_pv_tuples = sorted(self.query_pageviews(s), key=lambda x: random.random())

        for i, t in enumerate(article_pv_tuples):
            a = Article(t[0])
            a.rank = i
            articles.append(a)

        return articles[:n]


class MorelikeCandidateFinder():
    """
    Utility class for getting articles that are similar to
    a given seed article in a source Wikipedia via "morelike"
    search
    """
    def get_morelike_candidates(self, s, query, n):
        """
        Perform a "morelike" search via the Mediawiki search API. 
        First map the query to an article via standard search,
        and then get a list of related articles via morelike search
        """
        seed_list = wiki_search(s, query, 1)

        if len(seed_list) == 0:
            print('Seed does not map to an article')
            return []

        seed = seed_list[0]
        if seed != query:
            print('Query: %s  Article: %s' % (query, seed))
        results = wiki_search(s, seed, n, morelike=True)
        if results:
            results.insert(0, seed)
            print('Succesfull Morelike Search')
            return results
        else:
            print('Failed Morelike Search. Reverting to standard search')
            return wiki_search(s, query, n)
        


    def get_candidates(self, s, seed, n):
        """
        Wrap morelike search results into a list of articles
        """
        results = self.get_morelike_candidates(s, seed, n)

        articles = []

        for i, title in enumerate(results):
            a = Article(title)
            a.rank = i
            articles.append(a)

        return articles[:n]


class DeepCandidateFinder():
    """
    Candidate finder based on querying nearest neighbors
    from a semantic embedding of wikidata items
    """

    def __init__(self, Embedding):
        self.Embedding = Embedding


    def get_candidates(self, s, seed, n, min_similarity = 0.5):
        """
        1. resolve seed to an article
        2. map article to a Wikidata item
        3. get most similar wikidata items
        4. map resulting wikidata items back into articles
        """

        # resolve seed
        seed_list = wiki_search(s, seed, 1)
        if len(seed_list) == 0:
            print('Seed does not map to an article')
            return []
        title = seed_list[0]

        # map seed to wikidata item
        d = titles_to_items([title,], s)
        if len(d) == 0:
            print('Seed article does not have a Wikidata Item')
            return []
        item = d[title]

        # query embedding for nearest neighbors
        nn = self.Embedding.most_similar(item, n=n, min_similarity=min_similarity)
        if len(nn) == 0:
            print('Seed Item is not in the embedding or no neighbors above t. Reverting to morelike search')
            return MorelikeCandidateFinder().get_candidates(s, seed, n)

        # get nearest neighbors that exist in the source
        nn_items = [x[0] for x in nn]
        chunks = chunk_list(nn_items, 25)
        args_list = [(chunk, s) for chunk in chunks]
        results = thread_function(items_to_titles, args_list, n_threads = 10)
        # combine list of dicts in results into a single dict
        nn_items_to_titles = { k: v for d in results for k, v in d.items() }
        titles = [nn_items_to_titles[i] for i in nn_items if i in nn_items_to_titles]

        articles = []
        for i, title in enumerate(titles):
              a = Article(title)
              a.rank = i
              articles.append(a)

        return articles[:n]



def wiki_search(s, seed, n, morelike=False):
    """
    A client to the Mediawiki search API
    """
    if morelike:
        seed = 'morelike:' + seed
    mw_api = 'https://%s.wikipedia.org/w/api.php' % s
    params = {
        'action': 'query',
        'list': 'search',
        'format': 'json',
        'srsearch': seed,
        'srnamespace' : 0,
        'srwhat': 'text',
        'srprop': 'wordcount',
        'srlimit': n
    }
    try:
        response = requests.get(mw_api, params=params).json()
    except:
        print('Could not search for articles related to seed in %s. Choose another language.' % s)
        return [] 

    if 'query' not in response or 'search' not in response['query']:
        print('Could not search for articles related to seed in %s. Choose another language.' % s)
        return []

    response = response['query']['search']
    results =  [r['title'].replace(' ', '_') for r in response]
    if len(results) == 0:
        print('No articles similar to %s in %s. Try another seed.' % (seed, s))
        return []

    return results