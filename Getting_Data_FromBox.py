#!/usr/bin/env python
# coding: utf-8

# In[ ]:


#Import needed Packages
import os, datetime
import pandas as pd
import numpy as np
from box import LifespanBox
import sys


verbose = True
#verbose = False
snapshotdate = datetime.datetime.today().strftime('%m_%d_%Y')


#connect to Box (to get latest greatest curated stuff)
box_temp='/home/emily/Downloads/EA_BoxTemp' #location of local copy of curated data (where you want data to go)
box = LifespanBox(cache=box_temp)


# In[ ]:


# Functions that Need to Run to Pull Data
def foldercontents(folder_id):
    print(folder_id)
    filelist=[]
    fileidlist=[]
    folderlist=[]
    folderidlist=[]
    WUlist=box.client.folder(folder_id=folder_id).get_items(limit=None, offset=0, marker=None, use_marker=False, sort=None, direction=None, fields=None)
    for item in WUlist:
        if item.type == 'file':
            filelist.append(item.name)
            fileidlist.append(item.id)
        if item.type == 'folder':
            folderlist.append(item.name)
            folderidlist.append(item.id)
    files=pd.DataFrame({'filename':filelist, 'file_id':fileidlist})
    folders=pd.DataFrame({'foldername':folderlist, 'folder_id':folderidlist})
    return files,folders


def box2dataframe(fileid): #fileid is th efolder id
    harvardfiles, harvardfolders = foldercontents(fileid)
    return harvardfiles,harvardfolders
   # data4process = harvardfiles.loc[~(harvardfiles.filename.str.upper().str.contains('SCORE') == True)]
    #scores4process = harvardfiles.loc[harvardfiles.filename.str.upper().str.contains('SCORE') == True]
    #box.download_files(data4process.file_id) #will give df of information instead of list
    
def folderlistcontents(folderslabels,folderslist): # will want to tweak so that it can go more than one layer in
    bdasfilelist=pd.DataFrame()
    bdasfolderlist=pd.DataFrame()
    for i in range(len(folderslist)):
        print('getting file and folder contents of box folder ' +folderslabels[i])
        subfiles,subfolders=foldercontents(folderslist[i]) #foldercontents generates two dfs: a df with names and ids of files and a df with names and ids of folders
        bdasfilelist=bdasfilelist.append(subfiles)
        bdasfolderlist=bdasfolderlist.append(subfolders)
    return bdasfilelist,bdasfolderlist


# In[ ]:

#Make a function that will download all files in one folder when given the folder id from box:
def Download_Box_Files_in_Folder(folder_id):
    #Make Empty lists to be populated with info
    filelist=[]
    fileidlist=[]
    folderlist=[]
    folderidlist=[]
    
    #Connect to Box Folder of Interest
    WUlist=box.client.folder(folder_id=folder_id).get_items(limit=None, offset=0, marker=None, use_marker=False, sort=None, direction=None, fields=None)
    
    #For loop bassically saying for every folder/file in x folder, put in relevantlist above (e.g., filelist[])
    for item in WUlist:
        if item.type == 'file':
            filelist.append(item.name)
            fileidlist.append(item.id)
        if item.type == 'folder':
            folderlist.append(item.name)
            folderidlist.append(item.id)
            
            
    #Download all files in filelist[] to designated directory
    box.download_files(fileidlist, directory='/home/emily/Downloads/BOX TEST DOWNLOAD/', workers=20) #Should change directory to the directory we want the files to go to
    


# In[ ]:

#Make a list of Box Folder ID's that Have Data We want to Download 
folders_of_interest_CCN_UCLA=['151937194056','151937737346','151937251658','151937724042','151936699305']


# In[ ]:

#Run a for loop on folders_of_interest_X using the function we made above to download all files
for folder_id in folders_of_interest_CCN_UCLA:
    Download_Box_Files_in_Folder(folder_id)
