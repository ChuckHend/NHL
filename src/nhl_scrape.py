import requests
import string
import errno
import csv
import sys
import pandas as pd
import time
import lxml.html as LH
import requests

def get_player_ids(toCsv=True, return_list=True):
    '''returns a list of player ids used at hockey-reference.com'''
    letters = list(string.ascii_lowercase)
    players = []
    start = time.time()
    for letter in letters:

        res = requests.get('https://www.hockey-reference.com/players/{}/'.format(letter))
        try:
            res.raise_for_status()
            sys.stdout.write('\rFinished collecting letter [{}]'.format(letter))
            sys.stdout.flush()
        except IOError:
            print('\rError loading player data for letter [{}]'.format(letter))
        # parse out player IDs
        d = res.text
        a = d.split('<a href="/players/{}/'.format(letter))
        for x in a:
            line1 = x.split('.html')[0]
            if len(line1) < 15:
                players.append(line1)

    dropStrings = []
    for x in players:
        if not x[-1].isdigit():
            dropStrings.append(x)
        dropStrings = list(set(dropStrings))
    players = [c for c in players if c not in dropStrings]

    print('\rTime to retrieve: {}'.format(round(time.time()-start),2))

    if(toCsv):
        df = pd.DataFrame(players)
        df.to_csv('players_all.csv', index=False, header=False)
    if(return_list):
        return players

def text(elt):
    return elt.text_content().replace(u'\xa0', u' ')

def get_player_stats(players, years=range(1980,2018)):
    '''iterate through player list and year range to table of the game logs'''
    # TODO: consider starting with recent years for every player...for example:
    # Crosby did not play before 2005, so all years 1980-2004 will be blank

    header=['Date','G','Age','Tm','@','Opp','W/L.OT','G','A',
            'PTS','+/-','PIM','EV','PP','SH','GW','EV','PP','SH',
            'S','S%','SHFT','TOI','HIT','BLK','FOW','FOL','FO%']
    outHeader = header + ['playerID']
    playersDF = pd.DataFrame(columns=outHeader)

    totalWork = len(years)*len(players)
    i=0
    for year in years:
        for player in players:
            url = 'https://www.hockey-reference.com/players/c/{}/gamelog/{}'.format(player, year)
            r = requests.get(url)
            root = LH.fromstring(r.content)
            for table in root.xpath('//*[@id="gamelog"]'):
                data = [[text(td) for td in tr.xpath('td')] for tr in table.xpath('//tr')]
                data = [row for row in data if len(row)==len(header)]
                data = pd.DataFrame(data, columns=header)
                data['playerID']=player
                playersDF=pd.concat([playersDF, data])

                i = i + 1
                progress = round(i/totalWork,2)
                sys.stdout.write('\rPercentage Complete: {}'.format(progress))
                sys.stdout.flush()

    return playersDF
