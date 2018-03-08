import requests
import string
import errno
import csv
import pandas as pd

def get_player_ids(toCsv=True, return_df=True):
    '''returns a list of player ids used at hockey-reference.com'''
    # TODO: the list returns contains several bad strings, such as "skaters"
    # or "goalie" we'll want to remove these somehow
    letters = list(string.ascii_lowercase)
    for letter in letters:

        res = requests.get('https://www.hockey-reference.com/players/{}/'.format(letter))
        try:
            res.raise_for_status()
        except IOError:
            print('Error loading player data for letter [{}]'.format(letter))
        # parse out player IDs
        d = res.text
        a=d.split('<a href="/players/{}/'.format(letter))
        players = []
        for x in a:
            line1=x.split('.html')[0]
            if len(line1) < 15:
                players.append(line1)

    if(toCsv):
        df = pd.DataFrame(players, columns=["colummn"])
        df.to_csv('players_all.csv', index=False)
    if(return_df):
        return df
