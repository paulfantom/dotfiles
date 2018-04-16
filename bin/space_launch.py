#!/usr/bin/env python
"""
Copyright (C) 2018 Pawel Krupa (@paulfantom) - All Rights Reserved
Permission to copy and modify is granted under the MIT license

Print information about next space launch

Requirements:
  - python
  - requests library (http://docs.python-requests.org/en/master/)
"""

import requests

URL = "https://launchlibrary.net/1.3/launch/next/1"


def get_launch(url):
    """
    Get information about launch from given URL
    """
    response = requests.get(url)
    next_launch = response.json()['launches'][0]

    vids = next_launch['vidURLs']
    if vids is None:
        video = next_launch['vidURL']
    else:
        video = ", ".join(vids)
    mission = next_launch['missions'][0]['name']
    rocket = next_launch['rocket']['name']
    date = next_launch['windowstart']
    msg = "NEXT SPACE LAUNCH: {}, mission {} with {} rocket".format(date, mission, rocket)

    return msg if video is None else "{} watch at: {}".format(msg, video)


if __name__ == '__main__':
    print get_launch(URL)
