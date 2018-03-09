import requests
import string
import errno
import csv
import pandas as pd

def get_player_ids(toCsv=True, return_df=True):
    '''returns a list of player ids used at hockey-reference.com'''
    letters = list(string.ascii_lowercase)
    players = []
    for letter in letters:

        res = requests.get('https://www.hockey-reference.com/players/{}/'.format(letter))
        try:
            res.raise_for_status()
            print('Finished collecting letter [{}]'.format(letter))
        except IOError:
            print('Error loading player data for letter [{}]'.format(letter))
        # parse out player IDs
        d = res.text
        a=d.split('<a href="/players/{}/'.format(letter))
        for x in a:
            line1=x.split('.html')[0]
            if len(line1) < 15:
                players.append(line1)

    dropStrings=[]
    for x in players:
        if not x[-1].isdigit():
            dropStrings.append(x)
        dropStrings=list(set(dropStrings))
    players = [c for c in players if c not in dropStrings]

    if(toCsv):
        df = pd.DataFrame(players, columns=["colummn"])
        df.to_csv('players_all.csv', index=False)
    if(return_df):
        return players
