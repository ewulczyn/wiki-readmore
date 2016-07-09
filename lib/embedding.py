import numpy as np
import requests

class WikiEmbedding:

    def __init__(self, fname):
        
        self.w2idx = {}
        self.idx2w = []
    
        with open(fname, 'rb') as f:
            
            m, n = next(f).decode('utf8').strip().split(' ')
            self.E = np.zeros((int(m), int(n)))

            for i, l in enumerate(f):
                l = l.decode('utf8').strip().split(' ')
                w = l[0]
                self.E[i] = np.array(l[1:])
                self.w2idx[w] = i
                self.idx2w.append(w)
                
        self.E = self.normalize(self.E)
        self.idx2w = np.array(self.idx2w)


    def normalize(self, E):
        norms = np.linalg.norm(E, axis=1)
        E = E / norms[:, np.newaxis]
        return np.nan_to_num(E)

    def most_similar(self, w, n=10, min_similarity=0.5):
        """
        Find the top-N most similar words to w, based on cosine similarity.
        As a speed optimization, only consider neighbors with a similarity
        above min_similarity
        """
        if w not in self.w2idx:
            return []

        word_vector = self.E[self.w2idx[w]]
        scores = self.E.dot(word_vector)
        # only consider neighbors above threshold
        min_idxs = np.where(scores > min_similarity)
        ranking = np.argsort(-scores[min_idxs])[:n]
        nn_ws = self.idx2w[min_idxs][ranking]
        nn_scores = scores[min_idxs][ranking]
        return list(zip(list(nn_ws), list(nn_scores)))


def items_to_titles(items, lang):
    """
    Input: a list of Wikidata item ids
    Output: a dictionary mapping from ids to title in lang
    
    Note: items without an articlce in lang are not included in the output
    """
    lang += 'wiki'
    payload = {'action': 'wbgetentities',
               'props': 'sitelinks/urls',
               'format': 'json',
               'ids': '|'.join(items),               
              }
    r = requests.get('https://www.wikidata.org/w/api.php', params=payload).json()
    
    return parse_wikidata_sitelinks(r, lang, True)
    
    
def titles_to_items(titles, lang):
    """
    Input: a list of article titles in lang
    Output: a dictionary mapping from titles in lang to Wikidata ids
    
    Note: articles in lang without a Wikidata id are not included in the output

    """
    lang += 'wiki'
    payload = {'action': 'wbgetentities',
               'props': 'sitelinks/urls',
               'format': 'json',
               'sites': lang,
               'titles': '|'.join(titles),
              }
    r = requests.get('https://www.wikidata.org/w/api.php', params=payload).json()
    
    return parse_wikidata_sitelinks(r, lang, False)


def parse_wikidata_sitelinks(response, lang, item_to_title):
    """
    Helper function for parsing sitelinks from Wikidata Api
    """
    d = {}
    if 'entities' not in response:
        print ('No entities in response')
        return d

    for item, v in response['entities'].items():
        if 'sitelinks' in v:
            if lang in v['sitelinks']:
                title = v['sitelinks'][lang]['title'].replace(' ', '_')
                if item_to_title:
                    d[item] = title
                else:
                    d[title] = item
    return d