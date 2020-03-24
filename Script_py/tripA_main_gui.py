# -*- coding: utf-8 -*-

import pandas as pd
import os

import PySimpleGUI as sg
############################ Custom Classes ##################################

#un meta file in formato txt che contiene:
#    - ristorante name 
#    - numero di stelle medio 
#    - tutte le recensioni richieste dalla strategia
#    - per ogni recensione il numero di stelle, la data di inserimento, il nick name di chi ha fatto la recensione
#    - creto un csv per ogni strategia con colo1 numero di stelle, col2 il messaggio della recensione


import tripA_messages as tam 

base_path   = ''
work_path   = 'city.csv'
key_search  = 'Roma'
district_df = None
geko_env    = ''
strategy_1  = 'Last 5 comments on each restaurant in the neighborhood'
strategy_2  = 'Last 50 comments for most 20 restaurants rating in the neighborhood'
sub_area    = None  #{'id':[], 'district':[],'link':[]}
district_filtered=[]

# =============================================================================
# This funciton is the main of the program, it implements a graphic user interface that feed a responsive
# experience in the searching process. Interface is composed from two tabs.
# Tab City-District contains the imput field for the city word to be search. Once interted the city name, 
# button 'City Scrap' invoke external function 'scraping_city' that start the process that open 
# the web browser by Selenium driver and run the trip advisor's URL. 
# Once the execution has finished, second button 'Select District...' verify if the csv file containing 
# the list of districts exist. Then open it and show the result in a second windows. that windows contains 
# all of the districts beside a selectable check box. Might be possible select on or more districts 
# while will be used for post messages sraping.
# Current selection will be deleted in case button 'Select District...' is selected again 
# or the application will close.
# =============================================================================

def start_gui():
    window = sg.Window('Columns') 
	# this part generating input field for query string search and the path fot selenium geco driver do interface with browser app
    col_search = [[sg.Text('String Search:'   , size=(13, 1)), sg.Input(key_search, key='query')],
                  [sg.Text('Geckodriver Path:', size=(13, 1)), sg.Input(key='geko_folder'),  sg.FolderBrowse(),  sg.T('Design Firefox Only')]
                  ]
	# Hene is visualized the selection strategies
    col_test_mining = [[sg.T('Strategy 1:'), sg.Checkbox(strategy_1, size=(45, 1), key='s_1')],
                       [sg.T('Strategy 2:'), sg.Checkbox(strategy_2, size=(50, 1), key='s_2')]
                       ]
	# This tab contains the main section with button to start the seaping from the web page
    tab_search =  [[sg.T('Search TripAdvisor Restaurants')], 
                      [sg.Column(col_search)],
                      [sg.Button('City Scrap'), sg.Button('Select District...')]
                      ]
	# This tab contains the the section dedicated to strategy selection and messaging scrap
    tab_mining =  [[sg.T('Text Mining Restaurants')], 
                      [sg.Column(col_test_mining)],
                      [sg.Button('Execute')]
                      ]
	# This section collect both tabs for GUI visialization
    layout = [[sg.TabGroup([[sg.Tab('City-District', tab_search)],
                            [sg.Tab('Rule download'  , tab_mining)],
                            ])],
              [sg.Text('Folder Name'), sg.Input(key='folder'),  sg.FolderBrowse(),  sg.T('Repository Workspace')],
              [sg.Button('Quit'), sg.T('Master Data Science AA 2018-2019')]
              ]
	# This is the windows object that init the GUI interface and the listener action
    window = sg.Window('Download Restaurants Customers message by Neighborhood - v0.7', layout, grab_anywhere=False, finalize=True)
    window.BringToFront()

    try:
		# This infinite loop, handle to listener evento from the GUI console
        while(True):
			# On each event such as press button, the handle resturn the controle and fill above fields;
			# - event, which contains the event handle of the GUI
			# - values, it is an array that contain all of the input field of the GUI. Can be found by pay key/value
            event, values = window.Read()

            if event is not None and event in 'Quit':
                cancel(window)
                break
            # Check if the selenium driver path is initialie as well
            if values is not None:
                geko_folder = values['geko_folder']
                if geko_folder in '' or geko_folder is None:
                    sg.PopupTimed('Selenium Gecko Drive path must be assigned')
                    continue
                else:
                    geko_env=geko_folder+'/geckodriver.exe'
			# This is the event that catch the start of the scraping procedure after inserted the search word
            if event is not None and event in 'City Scrap':
                print('Execute Scrap')
                base_path = values['folder']
                # This is a control, if the outpath not defined, the program show a warning message
                if base_path in '' or base_path is None:
                    sg.PopupTimed('Folder path is empty. Local path will be used')
                else:
                    base_path=base_path+'/'

                query = values['query'].strip()
                # This is a control, if the query string is not defined, the program stop the execution with error message
                if query is not None:
                    print('execute_scrap')
                    city = values['query'].strip()
					# Here is invoked the scraping function to get the data from HTML page
                    tam.scraping_city(geko_env, base_path+work_path, city)
                else:
                    sg.PopupError('City in Search field is mandatory')
                    continue
			# This event is catched to be showed the district list popup and then select the district
            elif event is not None and event in 'Select District...':
                try:
                    base_path = values['folder']
                    if base_path in '' or base_path is None:
                        sg.PopupTimed('Folder path is empty. Local path will be used')
                    else:
                        base_path=base_path+'/'
                    print(base_path+work_path)
					# Get the list of scraped district details from a csv file
                    if os.path.isfile(base_path+work_path) :
                        district_df = pd.read_csv(base_path+work_path, sep='|', encoding = "UTF-8")
                    else:
                        sg.PopupError('District list is empty, execute "City Scrap" before to continue')
                        continue

                    names = district_df['district']
                    ids   = district_df['id']
#                    url   = district_df['link']

                    i=len(names)
					# prepare the popup with all sidtrict to be view
                    col_districts = [[sg.Checkbox(names[int(str(row)+str(col))], size=(15, 1), key=str(ids[int(str(row)+str(col))])) if (int(str(row)+str(col)) < i) else sg.T('') for col in range(10)] for row in range(15)]
                    parent_execution = [[sg.Column(col_districts, size=(800, 300), scrollable=True,vertical_scroll_only=False)]
                                        ]
                    foother = [[sg.Button('OK'), sg.Button('Cancel')]]
                    layout_districts = parent_execution+foother

                    print('Select District...')
					# below command open the new windows to the screen
                    popup = sg.Window('Select one or more Districts of '+values['query'], layout_districts, grab_anywhere=False)
                    popup.BringToFront()
					# Then wait an event (press OK button) before to continue
                    event_d, values_d  = popup.Read()
                    if event_d is not None and event_d in 'OK':
                        sub_area    = {'id':[], 'district':[],'link':[]}
#                        print('values_d', values_d)
						# Cycle upon the selection (one or more disctrict) and fill a datafram object
						# Dataframe object is a global variable that will be used later
                        for key in values_d.keys():
                            if values_d[key]:
                                sub_area['id'].append(district_df['id'][int(key)])
                                sub_area['district'].append(district_df['district'][int(key)])
                                sub_area['link'].append(district_df['link'][int(key)])
                        print(sub_area)
#                        print('district_filtered', district_filtered)
                    else:
                        print('Cancel, do nothing')

#                    col_districts = [[int(str(row)+str(col)) for col in range(10)] for row in range(20)]
#                    print(col_districts)
                    popup.close()
                except Exception as e:
                    print(e)
                    sg.PopupError(e)
			# This event is catched once pressed "Execute" button and invoke the function that do the scraping for restaurant's messages
            elif event is not None and event in 'Execute':
                print('Execute')
                if len(sub_area['id']) > 0:
                    
                    strg1 = values['s_1']
                    strg2 = values['s_2']
                    n_post=0
                    # Strategy 1: get last 05 posts from all restaurants in the selected district
                    if strg1:
                       n_post  = 5
                       top_row = 0
                       print('strategy 1:',strg1, 'strategy 2:', strg2, 'no of post:',n_post,'top_row', top_row)
                       tam.scraping_restaurant_name(geko_env, base_path, sub_area, n_post, top_row)
                    # Strategy 2: get last 50 posts from all restaurants in the selected district
                    if strg2:
                       n_post  = 50 
                       top_row = 20
                       print('strategy 1:',strg1, 'strategy 2:', strg2, 'no of post:',n_post,'top_row', top_row)
                       tam.scraping_restaurant_name(geko_env, base_path, sub_area, n_post, top_row)
                else:
                    sg.PopupError('No City district(s) has been selected from "City-District" Tab .')
                    continue
                    print('End of execution')
            else:
#                sg.PopupError('Something went wrong...')
                window.Close()
                break

    except Exception as e:
        print(e)
        sg.PopupError(e)
        window.Close()

def cancel(window):
    print ('Event Cancel')
    window.Close()

##################################################################################################################################
# This is the Main statement that start the entire program
start_gui()

