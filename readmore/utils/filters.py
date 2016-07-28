import itertools
import requests
from .helpers import thread_function, chunk_list

class Filter():
    """
    Filter interface
    """

    def filter_subset(self, s, t, articles):
        return []

    def filter(self, s, t, articles):
        """
        Wrapper to do filtering on chunks of
        articles concurrently
        """
        chunks = chunk_list(articles, 10)
        args_list = [(s, t, chunk) for chunk in chunks]
        results = thread_function(self.filter_subset, args_list)
        return list(itertools.chain.from_iterable(results))



class DisambiguationFilter(Filter):
    """
    Utility class for filtering out disambiguation
    pages using the Mediawiki API
    """

    def query_disambiguation_pages(self, s, titles):

        api = 'https://%s.wikipedia.org/w/api.php' % s

        params = {
                    'action': 'query',
                    'prop': 'pageprops',
                    'pprop': 'disambiguation',
                    'titles': '|'.join(titles),
                    'format': 'json',
                    }
        response = requests.get(api, params=params)
            
        if response:
            return response.json()
        else:
            print('Bad Disambiguation API response')
            return {}


    def parse_disambiguation_page_data(self, data):

        disambiguation_pages = set()

        if 'query' not in data or 'pages' not in data['query']:
            print('Error finding disambiguation pages')
            return set()

        for k,v in data['query']['pages'].items():
            if 'pageprops' in v and 'disambiguation' in v['pageprops']:
                title = v['title'].replace(' ', '_')
                disambiguation_pages.add(title)

        return disambiguation_pages


    def filter_subset(self, s, t, articles):
        titles = [a.title for a in articles]
        data = self.query_disambiguation_pages(s, titles)
        disambiguation_pages = self.parse_disambiguation_page_data(data)
        return [a for a in articles if a.title not in disambiguation_pages]



class TitleFilter(Filter):
    """
    Utility class for filtering out
    articles based on properties of the title alone
    """
    def title_passes(self, title):

            if ':' in title:
                return False 
            if title.startswith('List'):
                return False
            return True

    def filter(self, s, t, articles):
        """
        No need to thread this one
        """
        return [a for a in articles if self.title_passes(a.title)]


def apply_filters_chunkwise(s, t, candidates, n_recs, step = 100):

    """
    Since filtering is expensive, we want to filter a large list
    of candidates in chunks until we get the desired number of
    passing articles
    """
    filtered_candidates = []
    m = len(candidates)

    indices = [(i, i+step) for i in range(0, m, step)]

    # filter candidates in chunks, stop once we reach n_recs
    for start, stop in indices:
        print('Filtering Next Chunk')
        subset = candidates[start:stop]
        #subset = DisambiguationFilter().filter(s, t, subset)
        subset = TitleFilter().filter(s, t, subset)
        filtered_candidates += subset
        if len(filtered_candidates) >= n_recs:
            break

    return filtered_candidates
