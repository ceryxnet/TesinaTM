## kamboja - film - urla del silenzio

from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait as wait
from selenium.webdriver.common.by import By
from selenium import webdriver
from bs4 import BeautifulSoup as bfSoup
import pandas as pd
import urllib.request
import time
import os
import re

########################## Costants
RESTAURANT_CSV = 'restaurant.csv'
MESSAGE_CSV    = 'message.csv'
geko_env       = 'C:/ProgramData/geckodriver-v0.25.0/geckodriver.exe'
base_url       = 'https://www.tripadvisor.it'
URL            = base_url+'/Restaurants'

regex  = re.compile(r'[ .\']')
regex2 = re.compile(r'[#@"£$%&*+ç°§\n\r\']')
date_convertion = {'gennaio': '01', 'febbraio': '02', 'marzo': '03', 'aprile': '04', 'maggio': '05', 'giugno': '06', 'luglio': '07', 'agosto': '08', 'settembre': '09', 'ottobre': '10', 'novembre': '11', 'dicembre': '12'}

def init_selenium(geko_env):
    driver = webdriver.Firefox(executable_path=geko_env)
    return driver 


# =============================================================================
# @scraping_city
# input data:
#         - path containing the executable drive to be loaded
#         - output path where will be stored the downloaded data
#         - string containing the work search ( in this case the city name) 
# Output is a dataframe containing lits of:
#        - unique id
#        - area city name (neighborhood)
#        - url link for trip advisor page
# This function using both library selenium and BeautifulSoap, first is used to simulate the operator that fill
# the city name in the search field and click OK button to start the seach. Once the search has done, will be used 
# the second library to scrap the resulting of search in the page. Do the research inside the html DOM tree and 
# get all of the sub object containing the neighborhood name and neighborhood link.
# They will be used in next functino to get the restaurants list and then the restaurant's messages leaved form the customers.
# Function take care on which server the html coming up and apply the appropriate class marker to get the searching data.
# Result will be stored in memory through a dataset and then saved in a file with csv format. 
# =============================================================================        
def scraping_city(geko_env, file_name, search='Roma'):
    print('scraping_city start...')
    links_with_text = {'id':[], 'district':[],'link':[]}
    
    driver = init_selenium(geko_env)
    try:
        # This past of code hadle the response by selenium and simulate the operator actions upon the browser app 
        driver.get(URL)

        # Get the contry fiels and insert the word to be search
        input_country = driver.find_element_by_css_selector(".typeahead_input")
        # type the search word in the field
        input_country.send_keys(search)
        # wait one second to sumulate the human typing
        time.sleep(1)
        # Once inserted the work, from the page is appearing a quick list of word similarly to the own. 
        # whait 4 second before to perform the click on the quick list
        wait(driver, 4).until(EC.element_to_be_clickable((By.XPATH, "//span[text()='"+search+"']"))).click()
        # simulate the pressing to search button in the page                
        input_country = driver.find_element_by_css_selector(".caret-down")
        input_country.click()
        
        # Once executed the research, response is passed to BeautifulSoup which handle the HTML DOM and extract al needed data
        soup_l1=bfSoup(driver.page_source, 'lxml')
        
        # Find the sectin dedicated to contains the list of neighborhood
        # There is no way to understand from which server the response coming, so the unique is to check if the marker exist
        # if not, will be used the other one
        districts = soup_l1.find('div', {'class' : lambda e: e.endswith('filter_bar_neighborhood') if e else False}) # 
        if districts is None:
            print('Redirected to second server')
            header = soup_l1.find_all('div', {'class' : lambda e: e.startswith('common-filters-FilterWrapper__container') if e else False}) # common-filters-FilterWrapper__content--3RxLJ
            for h in header:
                title = h.find('div', {'class' : lambda e: e.startswith('common-filters-FilterWrapper__headerText') if e else False})  
                if title is not None:
                    if title.text in 'Quartiere':
                        districts = h
                        break
        
        l_districts = []
        # Result is a list of soap object that contains the neighborhood informations; restaurant name and restaurant link
        # It will extrafted in one shot with find_all function
        if districts is not None:
            l_districts = districts.find_all('a', href=True)
        idx=0
        print('l_districts len:', len(l_districts))
        for district in l_districts:
            if district is not None:
                links_with_text['id'].append(idx)
                links_with_text['district'].append(district.text.strip())
                links_with_text['link'].append(district['href'])
                idx+=1
        
        # Once all data is extracted, the rult will be saved in a file in csv format
        links_with_text_df = pd.DataFrame(links_with_text)
        links_with_text_df.to_csv(file_name, sep='|', encoding = "UTF-8", header=True, index=False)
    except Exception as e:
        print(e)
    driver.close()

# =============================================================================
# @scraping_restaurant_name 
# input data:
#         - path containing the executable drive to be loaded
#         - output path where will be stored the downloaded data
#         - dataframe which contains the list of neighborhood previously selected
#         - Number of messages to be get for each restaurant
#         - Number of restaurants to be get 
# Output is a dataframe containing lits of:
#        - unique id (external reference)
#        - restaurant name
#        - number of reviews
#        - rating level assigned to this restaurant
#        - url link for trip advisor page
# This function use BeautifulSoup library only, parse the HTML page and scrap the required data. 
# There are three nested cycle (from external to internal):
# - for all of the selected neighborhood link
# - this cycle is used to paginate for the specific neighborhood in case all restaurant are not presente in only one page 
# - last, get the list html object containing the restaurants details inside the page. Apply the algorithm to extract all request data
# Once scraped all the informatinos, dataframe resulting will be saved in a file with CSV format
# =============================================================================
def scraping_restaurant_name(geko_env, base_path, areas, n_post, top_row):

    idxs      = areas['id']
    districts = areas['district']
    url       = areas['link']
    # Cycle to all of neighborhood previously selected
    for idx in range(len(idxs)):

        district = districts[idx]
        district = regex.sub("_", district)
        f_key    = idxs[idx]
        url_next = url[idx]

        print('Index:',idx, 'District:', district, 'Reference:', f_key, 'Link:',url_next)
        
        links_with_text = {'id':[],'name':[], 'no_review':[],'no_rating':[], 'link':[] }
        while url_next is not None:
            # Open the connection to the site and get the HTML page
            reponse = urllib.request.urlopen(base_url+url_next)  
            html    = reponse.read()                  
            # Init the soap object (Root object)
            soup    = bfSoup(html, 'html.parser')                                
            # Find the list of restaurants, it is using a lambda expression that returning true whether is found
            # it is an object with a list of restaurant showed in the page
            restaurants = soup.find_all('div', {'class' : lambda e: e.startswith('_1llCuDZj') if e else False}) 
            print('restaurants', len(restaurants))
            no_rating = 0
            no_review = 0
            
            # Cycle the list and get all data with beautifulsop 'find' function. Parse the html dom by finding specifig marker
            for restaurant in restaurants:  
                soap_name   = restaurant.find('a', {'class' : lambda e: e.startswith('_15_ydu6b') if e else False}) # restaurants-list-ListCell__restaurantName--2aSdo
                soap_review = restaurant.find('span', {'class' : lambda e: e.startswith('restaurants-list-ListCell__userReviewCount') if e else False})  # restaurants-list-ListCell__userReviewCount--2a61M
                soap_rating = restaurant.find('span', {'class' : lambda e: e.startswith('ui_bubble_rating') if e else False})  # restaurants-list-ListCell__userReviewCount--2a61M
                # Get the rating restaurant by attribute class
                if soap_rating is not None:
                    _, no_rating = soap_rating.attrs['class'][1].split('_')
                
                # Get the number of restaurant's messages by attribute class
                if soap_review is not None:
                    no_review, _ = soap_review.text.split(' ')
                    no_review = regex.sub("", no_review)
                
                # Populate dataframe row with information extracted before
                if soap_name is not None:
                    links_with_text['id'].append(f_key)
                    links_with_text['no_rating'].append(int(no_rating))
                    links_with_text['no_review'].append(int(no_review))
                    links_with_text['name'].append(soap_name.get_text().strip())
                    # Get from html attribute the restaurant link 
                    links_with_text['link'].append(soap_name.attrs['href'])
                    print(f_key, no_rating, no_review, soap_name.get_text(), soap_name.attrs['href'])

            # Starting from sub tree HTML parent find a tag name 'a' having class='next' this contains the url to next page
            next_page = soup.find('a', {'class': 'next'})
            if next_page is not None and next_page.has_attr('href'):
                url_next = next_page.attrs['href']
            else:
                url_next = None
            print('url_next1', url_next)
            # Sleaping the process for for 3 seconds to simulate the human
            time.sleep(3)               
        
        # This part sort the restaurants by the number of review and take the firsts with most review from customers
        links_with_text_df = pd.DataFrame(links_with_text)
        if top_row != 0:
            links_with_text_df = links_with_text_df.sort_values('no_review',ascending = False).head(top_row)
        # Result will be saved in a separate file with csv format
        rest_names = base_path+district+'_'+str(n_post)+'_'+str(top_row)+'_'+RESTAURANT_CSV
        links_with_text_df.to_csv(rest_names, sep='|', encoding = "UTF-8", header=True, index=False)
        # Once all restaurants has scraped from pages, will be invoked next function while will do the scraping messages from them
        scraping_message(geko_env, base_path, district, n_post, top_row)

# =============================================================================
# @scraping_message 
# input data:
#         - path containing the executable drive to be loaded
#         - output path where will be stored the downloaded data
#         - dataframe which contains the list of restaurants previously downloaded
#         - Number of messages to be get for each restaurant
#         - Number of restaurants to be get 
# Output is a dataframe containing list of:
#        - unique id (external reference)
#        - date of posted review
#        - restaurant name (external reference)
#        - unser name alias (nick name)
#        - message reting level assigned
#        - text message posted from the customer
# This function using both library selenium and BeautifulSoap, first is used to simulate the click in the messages
# posted having hyper link "Show More" which hide part of message. Second is used to scrap the information from the 
# html page. There are three nested cycle (from external to internal):
# - cycle that list all restaurant's url link invoked by html request, once invoked save the response in a soap object to be parse 
# - this is used to paginate with next link in case all messages are not placed in only uone page
# - last cycle list the html object retrieved and apply the algorithm to extract the details data
# Once scraped all the informatinos, dataframe resulting will be saved in a file with CSV format
# =============================================================================
def scraping_message(geko_env, base_path, district, n_post, top_row):
    rest_names   = base_path+district+'_'+str(n_post)+'_'+str(top_row)+'_'+RESTAURANT_CSV
    rest_message = base_path+district+'_'+str(n_post)+'_'+str(top_row)+'_'+MESSAGE_CSV
    # Check if the input file exist in the local file system
    if os.path.isfile(rest_names) :
        restaurants_df = pd.read_csv(rest_names, sep='|', encoding = "UTF-8")
    # Check if the output file already exist and in case, delete it 
    if os.path.isfile(rest_message):
        os.remove(rest_message)
    # Init selenium environment
    driver = init_selenium(geko_env)
    # Prepare the list of the restaurants link - and name
    idxs  = restaurants_df['id']
    urls   = restaurants_df['link']
    names  = restaurants_df['name']
    # Start the first cycle for all restaurants
    for idx in range(len(idxs)):
        f_key    = idxs[idx]
        url_next = urls[idx]
        name     = names[idx]
        print(f_key, url_next)
        total_message=0        
        # Hese is prepared the output dataframe while contains a list of each object to be found
        links_with_text = {'id':[],'date':[], 'name':[], 'nickname':[], 'no_rating':[], 'message':[]}
        # This cycle navigate trough the next pages
        while url_next is not None:
            # This check id the number of requested message has scraped and stop the cycle in case
            if total_message >= n_post:
                break
            # This selenium control, simulate the clicl to expand hyperlink for all messages
            try:
                driver.get(base_url+url_next)
                # questo comando mi serve per espandere tutti i messaggi piu' lunghi di un certo numero di parolte, altrimenti li scarica con alla fina "piu..."
                wait(driver, 10).until(EC.element_to_be_clickable((By.XPATH, "//span[contains(.,'Più')]"))).click()
            except Exception as e:
                print (e)

            time.sleep(1)
            # From here BeautisulSoap get handle of the HTML dom to parse and extract the data
            soup=bfSoup(driver.page_source, 'lxml')
            
            # prendo la div che contiene la lista dei messaggi dell'intera pagina
            comments = soup.find_all('div', {'class' : 'rev_wrap'})
            print('comments:', len(comments))
            if len(comments) == 0:
                comments = soup.find_all('div', {'class' : 'prw_rup'})
                print('comments2:', len(comments))

            # Ciclo su tutti i messaggi e prendo le informazioni
            for comment in comments:
#                print(comment)
                # con questa il blocco l'esecuzione del programma ai primi 5 oppure 50 messaggi...
                if total_message >= n_post:
                    break
                # Per ogni oggetto div della lista recupero i dati che mi servono
                try:
                    soap_date    = comment.find('span', {'class' : lambda e: e.startswith('ratingDate') if e else False})  # restaurants-list-ListCell__userReviewCount--2a61M
                    soap_message = comment.find('p',    {'class' : lambda e: e.startswith('partial_entry') if e else False}) # restaurants-list-ListCell__restaurantName--2aSdo
                    soap_rating  = comment.find('span', {'class' : lambda e: e.startswith('ui_bubble_rating') if e else False})  # restaurants-list-ListCell__userReviewCount--2a61M
                    top_nik      = comment.find('div',  {'class' : lambda e: e.startswith('info_text') if e else False}) 
                    nickname = None
                    if top_nik:
                        print("info_text")
                        bodys        = top_nik.findChildren("div", recursive=False)
                        nickname     = bodys[0].text
                    top_nik      = comment.find('div',  {'class' : lambda e: e.startswith('username') if e else False}) 
                    if top_nik:
                        print("username")
                        bodys        = top_nik.findChildren("span", recursive=False)
                        nickname     = bodys[0].text
                except Exception as e:
                    print('No messages found.', e)
                

#                print('soap_rating', soap_rating)
                if soap_rating is not None:
                    _, no_rating = soap_rating.attrs['class'][1].split('_')

#                print("soap_date:", soap_date)
                if soap_date is not None:
                    day, s_mounth, year = soap_date.attrs['title'].split(' ')
                    s_date = year+'-'+date_convertion[s_mounth]+'-'+day

                if soap_message is not None and soap_date is not None and nickname is not None:
                    total_message +=1
                    print(f_key, s_date, name, nickname, no_rating, soap_message.get_text()[0:5])

                    # li salvo nel dataset che andra' a finire nel file
                    links_with_text['id'].append(f_key)
                    links_with_text['name'].append(name)
                    links_with_text['nickname'].append(nickname)
                    links_with_text['no_rating'].append(no_rating)
                    links_with_text['message'].append(regex2.sub(" ", soap_message.get_text()))
                    links_with_text['date'].append(s_date)

            if len(links_with_text['id']) >0:
                links_with_text_df = pd.DataFrame(links_with_text)
                if not os.path.isfile(rest_message):
                    links_with_text_df.to_csv(rest_message, sep='|', encoding = "UTF-8", header=True, index=False)
                else:
                    links_with_text_df.to_csv(rest_message, sep='|', mode='a', encoding = "UTF-8", header=False, index=False)
                links_with_text = {'id':[],'date':[], 'name':[], 'nickname':[], 'no_rating':[], 'message':[]}

            next_page = soup.find('a', {'class': 'next'})         # starting from soap parent find an xml tag with name 'a' and class='next'
#            print('next_page', next_page)
            if next_page is not None and next_page.has_attr('href'):
                url_next = next_page.attrs['href']
            else:
                url_next = None
            # print(url_next)
            time.sleep(1)
    if driver is not None:
        driver.close()

######################################################################################################################################
# Uncomment for debug
#sub_area={'id': [31, 41], 'district': ['Corso Francia', 'Grottarossa'], 'link': ['/Restaurants-g187791-zfn15621863-Rome_Lazio.html', '/Restaurants-g187791-zfn15621870-Rome_Lazio.html']}
#base_path="C:/Basket/temp/TextMining/"
#geko_env=base_path+"geckodriver.exe"
#scraping_city(geko_env, 'city.csv', 'Roma')
#scraping_restaurant_name(geko_env, '', sub_area, n_post=50, top_row=20)
#scraping_message(geko_env, '', 'Corso_Francia', 'Corso_Francia-restaurant.csv', 50, 20)
#scraping_message(geko_env, base_path, 'Prati', 5, 0)

