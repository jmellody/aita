import pandas as pd
import numpy as np
import dask.dataframe as dd
import sys

def read_posts(year=None):
    #read in posts
    posts = pd.read_parquet(f'{datafolder}AmItheAsshole_submissions.parquet').astype({'id':'str','selftext':'str', 'title': 'str', 'author': 'str', 'created_utc': 'float', 'score': 'int', 'distinguished': 'str','link_flair_text': 'str', 'link_flair_css_class': 'str'})
    
    posts['text'] = posts['title'] + ' ' + posts['selftext'] #combine title and selftext in one text column

    #clean text --> just remove those that were removed by mods --> just doing this for the purposes of getting the topics, will put back in after
    posts = posts[~(posts['selftext'] == '[deleted]')]
    posts = posts[~(posts['selftext'] == '[removed]')]
    posts = posts[~(posts['selftext'] == '['']')]

    posts['created'] = pd.to_datetime(posts['created_utc'], unit = 's')
    posts = posts.sort_values('created')
    posts['year'] = posts['created'].dt.year
    posts['month'] = posts['created'].dt.month

    #GET TOPICS
    post_topics = pd.read_parquet(f'{datafolder}posttopics.parquet')
    posts['topic'] = post_topics['topic'].values
    posts['topic_name'] = post_topics['topic_name'] #map to names

    #read in deleted/removed posts and add to posts that have topics
    posts2 = pd.read_parquet(f'{datafolder}AmItheAsshole_submissions.parquet').astype({'id':'str','selftext':'str', 'title': 'str', 'author': 'str', 'created_utc': 'float', 'score': 'int', 'distinguished': 'str','link_flair_text': 'str', 'link_flair_css_class': 'str'})

    posts2 = posts2[(posts2['selftext'] == '[deleted]') | (posts2['selftext'] == '[removed]') | (posts2['selftext'] == '['']')] # limit to deleted/removed posts

    posts2['text'] = posts2['title'] + ' ' + posts2['selftext'] #combine text into one column
    posts2['created'] = pd.to_datetime(posts2['created_utc'], unit = 's')
    posts2 = posts2.sort_values('created')
    posts2['year'] = posts2['created'].dt.year
    posts2['month'] = posts2['created'].dt.month

    posts = pd.concat([posts, posts2]) #concatenate two dfs

    if year is not None:
        posts = posts[posts['year'] == year]

    return posts

def read_coms(useableposts):
    # Read in comments using Dask (with only the necessary columns)
    coms = dd.read_parquet(f'{datafolder}AmItheAsshole_comments.parquet', columns=[
        'id', 'body', 'author', 'created_utc', 'score', 'link_id', 'parent_id', 'distinguished'
    ], engine='pyarrow')

    # Clean the text column by filtering out unwanted entries
    coms = coms[~(coms['body'] == '[deleted]')]
    coms = coms[~(coms['body'] == '[removed]')]
    coms = coms[~(coms['body'] == '['']')]
    coms = coms[~(coms['body'] == ' ')]
    coms = coms[~(coms['author'] == '[deleted]')]
       
    #remove negative comments
    print(len(coms[coms['score'] >= 1]) / len(coms))
    coms = coms[coms['score'] >= 1]

    # Clean up 'link_id' and filter comments based on 'link_id' being in the 'useableposts' list
    coms['link_id'] = coms['link_id'].str[3:]  # Remove the first 3 characters from 'link_id'
    coms = coms[coms['link_id'].isin(useableposts)]  # Filter based on 'useableposts'

    # Compute the result (since Dask operates lazily, this triggers the actual computation)
    coms = coms.compute()

    return coms


def identify_judgements(coms, year=None):
    ## identify if comment contains judgement flairs or phrases
    termlist = ['\\byta\\b', "you're the asshole", 'youre the asshole', 'u r the asshole', 'ur the asshole', '\\bywbta\\b', 'you would be the asshole', "you'd be the asshole", '\\bnta\\b', 'not the asshole', '\\bywnbta\\b', 'you would not be the asshole', "you'd not be the asshole", '\\besh\\b', 'everyone sucks here', '\\bnah\\b', 'no assholes here',  '\\binfo\\b', 'not enough info']
    terms = '|'.join(termlist)

    wordpresences = pd.DataFrame({word: (coms['body'].str.contains(word, case=False)) for word in termlist}) #get df of word presences
    wordpresences = wordpresences.astype(int) # turn booleans into ints
    coms = pd.concat([coms, wordpresences], axis=1) # Concat word presences df with main comments df
    coms['YTA'] = coms['\\byta\\b']+ coms["you're the asshole"] + coms['youre the asshole'] + coms['u r the asshole'] + coms['ur the asshole'] + coms['\\bywbta\\b'] + coms['you would be the asshole'] + coms["you'd be the asshole"]
    coms['NTA'] = coms['\\bnta\\b'] + coms['not the asshole'] + coms['\\bywnbta\\b'] + coms['you would not be the asshole'] + coms["you'd not be the asshole"]
    coms['ESH'] = coms['\\besh\\b'] + coms['everyone sucks here']
    coms['NAH'] = coms['\\bnah\\b'] + coms['no assholes here']
    coms['INFO'] = coms['\\binfo\\b'] + coms['not enough info']

    #Create a binary variable for whether or not a judgement is expressed with an abbreviation
    coms['judgement_abbrev'] = 0
    coms.loc[(coms['\\byta\\b'] == 1) | (coms['\\bywbta\\b'] == 1) | (coms['\\bnta\\b'] == 1) | (coms['\\bywnbta\\b'] == 1) | (coms['\\besh\\b'] == 1) | (coms['\\bnah\\b'] == 1) | (coms['\\binfo\\b'] == 1), 'judgement_abbrev'] = 1
    coms = coms.drop(columns = ['\\byta\\b', "you're the asshole", 'youre the asshole', 'u r the asshole', 'ur the asshole', '\\bywbta\\b', 'you would be the asshole', "you'd be the asshole", '\\bnta\\b', 'not the asshole', '\\bywnbta\\b', 'you would not be the asshole', "you'd not be the asshole", '\\besh\\b', 'everyone sucks here', '\\bnah\\b', 'no assholes here',  '\\binfo\\b', 'not enough info'])
    
    #REMOVE AMBIGUOUS COMMENTS
    coms['judgement_sum'] = coms['YTA'] + coms['NTA'] + coms['ESH'] + coms['NAH'] + coms['INFO']
    coms = coms[coms['judgement_sum'] <= 1] # remove rows that have more than one judgement

    output_filename = f'{datafolder}AITA_comments_intermediate_{year if year is not None else 'all'}.parquet'
    
    coms.to_parquet(output_filename, row_group_size = 10**6)

    return coms


def remove_lower_tier_comments(coms):
    coms = coms[coms['parent_id'] == coms['link_id']]

    return coms

def get_weighted_judgement_scores(coms):

    # Calculate weighted columns
    coms['YTA_weighted'] = coms['YTA'] * coms['score']
    coms['NTA_weighted'] = coms['NTA'] * coms['score']
    coms['ESH_weighted'] = coms['ESH'] * coms['score']
    coms['NAH_weighted'] = coms['NAH'] * coms['score']
    coms['INFO_weighted'] = coms['INFO'] * coms['score']
    
    # Group by 'link_id' and calculate sums efficiently
    coms_sum = coms.groupby('link_id')[['YTA_weighted', 'NTA_weighted', 'ESH_weighted', 'NAH_weighted', 'INFO_weighted']].sum()

    # Merge the summed scores back into the original 'coms' dataframe
    coms = coms.merge(coms_sum, on='link_id', suffixes=('', '_sum'))
    
    return coms


def get_final_judgements(coms):

    coms = coms[coms['judgement_sum'] > 0] # remove those that have no judgement

    #get judgement based on highest scored comment --------
    def get_judgement(row):
        if row['YTA'] == 1:
            return 'YTA'
        elif row['NTA'] == 1:
            return 'NTA'
        elif row['ESH'] == 1:
            return 'ESH'
        elif row['NAH'] == 1:
            return 'NAH'
        elif row['INFO'] == 1:
            return 'INFO'
        else:
            return 'No Judgment'  # In case neither YTA nor NTA are present


    # Step 1: Group by 'link_id' and identify the row with the highest score in each group
    coms['max_score'] = coms[(coms['YTA'] != 0) | (coms['NTA'] != 0) | (coms['ESH'] != 0) | (coms['NAH'] != 0) | (coms['INFO'] != 0)].groupby('link_id')['score'].transform('max')
    
    # Step 2: Create the 'judgement' column, which will be the judgment of the highest scored comment
    # For each group, we assign the judgment to the row with the highest score
    coms['highest_com_judgement'] = coms.apply(lambda row: get_judgement(row) if row['score'] == row['max_score'] else None, axis=1)
    
    # Step 3: Fill the 'judgement' column for all other rows within the same 'link_id' group
    coms['highest_com_judgement'] = coms.groupby('link_id')['highest_com_judgement'].transform('first')
    
    # Drop the 'max_score' column as it is no longer needed
    coms = coms.drop(columns=['max_score'])

    # Get judgement based on judgement with the highest score ---------
    coms['majority_judgement'] = coms[['YTA_weighted_sum', 'NTA_weighted_sum', 'ESH_weighted_sum', 'NAH_weighted_sum', 'INFO_weighted_sum']].idxmax(axis=1)
    coms['majority_judgement'] = coms['majority_judgement'].apply(lambda x: x[:-13])

    coms = coms[~coms['majority_judgement'].isna()] # remove those with no judgements at all
    coms = coms[~coms['highest_com_judgement'].isna()] # remove those with no judgements at all

    #DROP IF THE TWO JUDGEMENTS DON"T AGREEEEE?????
    print(len(coms[coms['highest_com_judgement'] == coms['majority_judgement']]) / len(coms))
    coms = coms[coms['highest_com_judgement'] == coms['majority_judgement']]
    
    return coms

def create_data(posts, coms):
    coms['type'] = 'comment'
    posts['type'] = 'post'
    coms['created'] = pd.to_datetime(coms['created_utc'], unit = 's')
    coms = coms.drop(columns = ['created_utc'])
    data = pd.concat([coms, posts])
    del coms
    data['postid'] = np.where(data['type'] == 'comment', data['link_id'], data['id']) #create postid
    
    return data

def create_deleted_indicator_columns(data):
    data = data.sort_values('created')
    data['posttext'] = data.groupby('postid')['selftext'].transform('first')
    data['deleted'] = 0
    data['removed'] = 0
    data['empty'] = 0
    data.loc[data['posttext'] == '[deleted]', 'deleted'] = 1
    data.loc[data['posttext'] == '[removed]', 'removed'] = 1
    data.loc[(data['posttext'] == '') | (data['posttext'] == ' '), 'empty'] = 1
    data = data.drop(columns = 'posttext')
    
    return data


def get_time_since_op(data):
    # create difference in created time between post and comment
    data = data.sort_values('created')
    data['posttime'] = data.groupby('postid').created.transform('first')
    data['time_diff'] = data['created'] - data['posttime']
    data['time_diff_min'] = data['time_diff'].dt.total_seconds() / 60

    data['hour'] = data['created'].dt.hour # hour of day
    data['dayofweek'] = data['created'].dt.weekday # day of week

    #limit to only comments within 18 hours of post
    data['treated'] = 0
    data.loc[(data['time_diff_min'] > 1080), 'treated'] = 1
    
    return data

def first_op_com(data):
    #denote whether comment was made by post OP
    data['op_comment'] = 0
    data = data.sort_values('created')
    data['post_op'] = data.groupby('postid')['author'].transform('first')
    data.loc[data['author'] == data['post_op'], 'op_comment'] = 1 #denote which comments were made by OP
    data.loc[data['type'] == 'post', 'op_comment'] = 0 #can't be an OP comment if it's a post

    # create binary variable for if post has a post from OP or not
    data['op_com_sum'] = data.groupby('postid')['op_comment'].transform('sum')
    data['has_op_com'] = 0
    data.loc[data['op_com_sum'] > 0, 'has_op_com'] = 1
    data = data.drop(columns = ['op_com_sum'])

    #Denote whether comment is first comment made by post OP
    data = data.reset_index()
    data = data.drop(columns = ['index'])
    data['first_op_com_index'] = data.groupby('postid')['op_comment'].transform(lambda x: x.ne(0).idxmax())
    data.loc[(data['has_op_com'] == 0),'first_op_com_index'] = 0
    data['first_op_com'] = 0
    data.loc[(data.index == data['first_op_com_index']) & (data['op_comment'] == 1), 'first_op_com'] = 1
    data['op_com_yet'] = 0
    data.loc[(data.index >= data['first_op_com_index']) & (data['has_op_com'] == 1), 'op_com_yet'] = 1
    data = data.drop(columns = ['first_op_com_index'])

    # Add the time of the first op com to each row
    op_first_time_coms = data[data['first_op_com'] == 1]
    op_first_time_coms = op_first_time_coms[['postid','created']]
    op_first_time_coms = op_first_time_coms.rename(columns = {'created': 'first_com_time'})
    data = pd.merge(data, op_first_time_coms, how = 'left', on = 'postid')

    data['time_from_first_op_com'] = data['created'] - data['first_com_time'] # get time from first op com
    
    data['time_from_first_op_com_min'] = data['time_from_first_op_com'].dt.total_seconds() / 60
    
    return data

def get_topic(data):
    data['posttopic'] = data.groupby('postid')['topic'].transform('first')
    data['posttopicname'] = data.groupby('postid')['topic_name'].transform('first')
    
    return data
    
def get_comment_competition(data):
    data['comment_competition'] = data.groupby('postid')['time_diff_min'].rank(method='first')
    data['comment_competition'] = data['comment_competition'] - 1 # to start counting from the second comment
    data['comment_competition_votes'] = data.groupby('postid')['score'].cumsum()
    data['comment_competition_votes'] = data['comment_competition_votes'] - data['score']
    
    return data

def get_author_info(data):
    authordata = pd.read_parquet(f'{datafolder}authordata.parquet', columns = ['id','author_skill'])
    data = pd.merge(data, authordata, on = 'id', how = 'left')

    return data

def get_comment_length(data):
    data['text'] = np.where(data['type'] == 'post', data['text'], data['body'])
    data['comment_length'] = data['text'].str.len()

    return data


def limit_sample(data):
    
    #LIMIT TO ONLY POSTS WHERE JUDGEMENT IS YTA OR NTA - based on both methods
    data = data[(data['majority_judgement'] == 'YTA') | (data['majority_judgement'] == 'NTA')]

    # REMOVE COMMENTS THAT DON"T HAVE A JUDGEMENT --> SAMPLE FOR ANALYSIS IS COMMENTS W/ A JUDGEMENT
    data = data[~((data['YTA'] == 0) & (data['NTA'] == 0))] # LIMIT TO COMMENTS THAT ARE EITHER YTA OR NTA JUDGEMENTS

    #remove mod comments
    data = data[~(data['distinguished'] == 'moderator')]

    #Remove moderator and bot comments
    data = data[~(data['author'] == 'AutoModerator')]
    data = data[~(data['author'] == 'Judgement_Bot_AITA')]
    
    data['num_comments'] = data.groupby('postid')['id'].transform('count')
    
    return data


def get_main_variables(data):

    data = get_comment_competition(data)
    
    # #WEIGHTED
    data['cum_YTA'] = data.groupby('postid')['YTA_weighted'].cumsum() # cumulative sum of weighted YTA but don't include current row
    data['cum_NTA'] = data.groupby('postid')['NTA_weighted'].cumsum()

    #subtract current row from the cumulative score
    data['cum_YTA'] = data['cum_YTA'] - data['YTA_weighted']
    data['cum_NTA'] = data['cum_NTA'] - data['NTA_weighted']

    # cumulative sum of weighted NTA but don't include current row
    data['cum_score'] = np.where((data['cum_YTA'] != 0) | (data['cum_NTA'] != 0), (data['cum_YTA'] / (data['cum_NTA'] + data['cum_YTA'])), 0.5)
    data['cum_score_absolute'] = data['cum_YTA'] - data['cum_NTA']
    

    #UNWEIGHTED
    data['cum_YTA_unweighted'] = data.groupby('postid')['YTA'].cumsum() # cumulative sum of weighted YTA but don't include current row
    data['cum_NTA_unweighted'] = data.groupby('postid')['NTA'].cumsum()

    # subtract current row from cumulative score
    data['cum_YTA_unweighted'] = data['cum_YTA_unweighted'] - data['YTA']
    data['cum_NTA_unweighted'] = data['cum_NTA_unweighted'] - data['NTA']

    # cumulative sum of unweighted NTA but don't include current row
    data['cum_score_unweighted'] = np.where((data['cum_YTA_unweighted'] != 0) | (data['cum_NTA_unweighted'] != 0), (data['cum_YTA_unweighted'] / (data['cum_NTA_unweighted'] + data['cum_YTA_unweighted'])), 0.5)
    data['cum_score_absolute_unweighted'] = data['cum_YTA_unweighted'] - data['cum_NTA_unweighted']

    ##WEIGHTED
    #agree with consensus?
    data['consensus_agree'] = 0
    data.loc[(data['cum_score_absolute'] == 0), 'consensus_agree'] = 1 # agree with consensus if current consensus is 0 - b/c you make the consensus
    data.loc[(data['cum_score_absolute'] < 0) & (data['NTA'] == 1), 'consensus_agree'] = 1
    data.loc[(data['cum_score_absolute'] > 0) & (data['YTA'] == 1), 'consensus_agree'] = 1
    data.loc[(data['NTA'] == 1) & (data['YTA'] == 1), 'consensus_agree'] = 0 # THERE SHOULD BE NONE OF THESE

    data['current_consensus'] = np.where((data['cum_score'] >= 0.5), data['cum_score'], 1 - data['cum_score']) # take [0,1] cum_score and turn into [0.5,1]
    data['current_consensus'] = data['current_consensus'].astype('float')

    ##UNWEIGHTED
    #agree with consensus?
    data['consensus_agree_unweighted'] = 0
    data.loc[(data['cum_score_absolute_unweighted'] == 0), 'consensus_agree_unweighted'] = 1 # agree with consensus if current consensus is 0 - b/c you make the consensus
    data.loc[(data['cum_score_absolute_unweighted'] < 0) & (data['NTA'] == 1), 'consensus_agree_unweighted'] = 1
    data.loc[(data['cum_score_absolute_unweighted'] > 0) & (data['YTA'] == 1), 'consensus_agree_unweighted'] = 1
    data.loc[(data['NTA'] == 1) & (data['YTA'] == 1), 'consensus_agree_unweighted'] = 0 # THERE SHOULD BE NONE OF THESE

    data['current_consensus_unweighted'] = np.where((data['cum_score_unweighted'] >= 0.5), data['cum_score_unweighted'], 1 - data['cum_score_unweighted'])
    data['current_consensus_unweighted'] = data['current_consensus_unweighted'].astype('float')
    
    data['exists'] = 1
    data['certainty'] = data.groupby('postid')['exists'].cumsum() / data.groupby('postid')['postid'].transform('size')
    data['certainty'] = data['certainty'].astype('float')
    
    return data


def main():

    # #read in posts and comments
    if len(sys.argv) > 1:
        year = int(sys.argv[1])
    else:
        year = None
    
    posts = read_posts(year) # read in posts
    print('Finished Reading Posts')
    useableposts = posts['id'].tolist() # get list of useable posts
    coms = read_coms(useableposts) # read in comments
    print('Finished Reading Comments')
    coms = identify_judgements(coms, year) #identify judgements
    print('Finished Identifying Comment Judgements')

    coms = pd.read_parquet(f'{datafolder}AITA_comments_intermediate_{year if year is not None else 'all'}.parquet')
    
    #remove lower tier coms
    coms['parent_id'] = coms['parent_id'].apply(lambda x: x[3:] if x.startswith('t') else x)
    low_coms = coms[coms['parent_id'] != coms['link_id']]
    low_coms.to_parquet(f'{datafolder}aita_low_tier_coms_{year if year is not None else 'all'}.parquet')
    del low_coms
    coms = remove_lower_tier_comments(coms)
    
    coms = get_weighted_judgement_scores(coms)
    coms = get_final_judgements(coms)
    print('Finished Calculating Post Judgements')
    
    data = create_data(posts, coms) #combine posts and comments 
    print('Combined DF Created')
    
    data = create_deleted_indicator_columns(data) #create variables for whether the post is deleted, removed, or 0

    # #GET VARIABLES
    #add back in lower tier coms
    low_coms = pd.read_parquet(f'{datafolder}aita_low_tier_coms_{year if year is not None else 'all'}.parquet')
    low_coms['type'] = 'comment'
    low_coms['postid'] = low_coms['link_id']
    low_coms['created'] = pd.to_datetime(low_coms['created_utc'], unit = 's')
    data = pd.concat([data, low_coms])    
    
    data = get_time_since_op(data) # get time_since_op variables
    print('Created Time Variable')
    data = first_op_com(data) # get if comment is first comment by op
    print('Created First OP Com Variable')

    #then remove lower tier comments again
    data = data[~((data['type'] == 'comment') & (data['parent_id'] != data['link_id']))]
    
    data = get_topic(data) # get post topic
    print('Created Topic Variable')
    data = get_author_info(data) # get author info
    print('Created Author Info Variable')
    data = get_comment_length(data) # get info on length of comment
    print('Created Comment Length Variable')    
    data = limit_sample(data) # limit the sample
    print('Finished Limiting Sample')
    data = get_main_variables(data)
    print('Finished Creating Main Data')
    
    
    # ## --------------------  SAVE DATA -------------------###############    

    #create some variables
    data['postid_encoded'] = data.groupby('postid').ngroup() #assign a unique id to each post
    data['month'] = data['created'].dt.month
    data['year'] = data['created'].dt.year

    


    #if current_consensus is infinity, replace with nan
    data['current_consensus'] = data['current_consensus'].replace([np.inf, -np.inf], np.nan)

    data = data.drop(columns = ['body', 'link_id', 'parent_id', 'distinguished', 'YTA','NTA','ESH','NAH','INFO','YTA_weighted',
                                'NTA_weighted','ESH_weighted','NAH_weighted','INFO_weighted', 'YTA_weighted_sum', 'NTA_weighted_sum', 'ESH_weighted_sum',
                                'NAH_weighted_sum', 'INFO_weighted_sum', 'link_flair_text', 'link_flair_css_class', 'author_flair_text', 'author_flair_css_class',  
                                'exists', 'type','title','selftext','text','cum_YTA','cum_NTA', 'cum_YTA_unweighted', 'cum_NTA_unweighted', 'time_diff', 'id',
                                'posttime', 'cum_score', 'cum_score_unweighted', 'exists', 'topic_name', 'posttopicname',
                                'time_from_first_op_com', 'created_utc'])


    
    
    #save
    #data.to_parquet(f'{datafolder}aita_data_{year if year is not None else 'all'}.parquet', row_group_size = 10**6) #create parquet
    data.to_stata(f'{datafolder}aita_data_{year if year is not None else 'all'}.dta', version=118) #create stata data file

    print('Finished Saving Data')


if __name__ == "__main__":

    datafolder = '/Users/jm7581/Documents/Projects/Active/AITA/data/'
    
    #run main
    main()
  
