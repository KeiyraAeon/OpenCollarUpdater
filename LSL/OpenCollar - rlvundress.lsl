////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollar - rlvundress                             //
//                                 version 3.958                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////


// 3.936 New feature! Smartstrip. When smartstrip is activated, the standard clothing removal folder will use detachallthis instead of remoutfit, to remove everything in the same folder or child folders of the item being removed. For people with a sensibly set up #RLV, this makes this a far more useful option! Because lots of people *don't* have a #RLV folder set up for this, we also have a notecard to give to help people with setting up folders. Yay! Smartstrip gets turned on and off via the menus or via the chat commands "smartstrip on" and "smartstrip off". Owners and Wearers can both change this setting. However! We also have a g_kSmartUser key. If someone other an Owner or Wearer selects it, their key gets dumped into this value, which is not saved. This allows other people to activate it for themselves only, for that session only. As an additional bonus, removing clothing can now be accessed by an easy chat command, "strip (item)" or "strip all". For now, I haven't changed the behaviour of strip all, however the code is there commented out if we think it's a good idea for strip all to use smartstrip.


//gives menus for clothing and attachment, stripping and locking

string g_sSubMenu = "Un/Dress";
string g_sParentMenu = "RLV";

list g_lChildren = ["Rem Clothing","Rem Attachment"]; //,"LockClothing","LockAttachment"];//,"LockClothing","UnlockClothing"];
list g_lSubMenus= [];
string SELECT_CURRENT = "*InFolder";
string SELECT_RECURS= "*Recursively";
list g_lRLVcmds = ["attach","detach","remoutfit", "addoutfit","remattach","addattach"];


integer g_iSmartStrip=FALSE; //use @detachallthis isntead of remove
string SMARTON="☐ SmartStrip";
string SMARTOFF = "☒ SmartStrip";
string SMARTHELP = "Help";
string g_sSmartHelpCard = "OpenCollar Guide";
string g_sSmartToken="smartstrip";
//key g_kSmartUser; //we store the last person to select if they are not wearer/owner, so that it can be switched on for current user without changing setting.


list g_lSettings;//2-strided list in form of [option, param]
string CTYPE = "collar";

list LOCK_CLOTH_POINTS = [
    "Gloves",
    "Jacket",
    "Pants",
    "Shirt",
    "Shoes",
    "Skirt",
    "Socks",
    "Underpants",
    "Undershirt",
    "Skin",
    "Eyes",
    "Hair",
    "Shape",
    "Alpha",
    "Tattoo",
    "Physics"
        ];


list DETACH_CLOTH_POINTS = [
    "Gloves",
    "Jacket",
    "Pants",
    "Shirt",
    "Shoes",
    "Skirt",
    "Socks",
    "Underpants",
    "Undershirt",
    "xx", //"skin", those are not to be detached, so we ignore them later
    "xx", //"eyes", those are not to be detached, so we ignore them later
    "xx", //"hair", those are not to be detached, so we ignore them later
    "xx", //"shape", those are not to be detached, so we ignore them later
    "Alpha",
    "Tattoo",
    "Physics"
        ];

list ATTACH_POINTS = [//these are ordered so that their indices in the list correspond to the numbers returned by llGetAttached
    "None",
    "Chest",
    "Skull",
    "Left Shoulder",
    "Right Shoulder",
    "Left Hand",
    "Right Hand",
    "Left Foot",
    "Right Foot",
    "Spine",
    "Pelvis",
    "Mouth",
    "Chin",
    "Left Ear",
    "Right Ear",
    "Left Eyeball",
    "Right Eyeball",
    "Nose",
    "R Upper Arm",
    "R Forearm",
    "L Upper Arm",
    "L Forearm",
    "Right Hip",
    "R Upper Leg",
    "R Lower Leg",
    "Left Hip",
    "L Upper Leg",
    "L Lower Leg",
    "Stomach",
    "Left Pec",
    "Right Pec",
    "Center 2",
    "Top Right",
    "Top",
    "Top Left",
    "Center",
    "Bottom Left",
    "Bottom",
    "Bottom Right",
    "Neck",
    "Avatar Center"
        ];

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION = 6003; //RLV Plugins can recieve the used rl viewer version upon receiving this message..

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed


integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;


string UPMENU = "BACK";

string ALL = " ALL";
string TICKED = "☒ ";
string UNTICKED = "☐ ";

//variables for storing our various dialog ids
key g_kMainID;
key g_kClothID;
key g_kAttachID;
key g_kLockID;
key g_kLockAttachID;

integer g_iRLVTimeOut = 60;

integer g_iClothRLV = 78465;
integer g_iAttachRLV = 78466;
integer g_iListener;
key g_kMenuUser; // id of the avatar who will get the next menu after asynchronous response from RLV
integer g_iMenuAuth; // auth level of that user

integer g_iRLVOn = FALSE;

list g_lLockedItems; // list of locked clothes
list g_lLockedAttach; // list of locked attachmemts

key g_kWearer;
string g_sScript;
string g_sWearerName;
integer g_iAllLocked = 0;  //1=all clothes are locked on

Debug(string sMsg)
{
    //llOwnerSay(llGetScriptName() + ": " + sMsg);
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    }
    else
    {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

MainMenu(key kID, integer iAuth)
{
    //string sPrompt = "\n\nNote: Keep in mind that mesh clothing is worn as attachments and in most cases together with alpha masks which are worn as clothing layers. It is recommended to explore the possibilities of #RLV Folders for a smooth un/dressing experience.\n";
    string sPrompt = "\n\nNote: Many clothes, and almost all mesh, mixes layers and attachments. With a properly set up #RLV folder (click "+SMARTHELP+" for info), the SmartStrip option will allow these to be removed automatically. Otherwise, it is recommended to explore the #RLV Folders menu for a smoother un/dressing experience.";
    list lButtons = g_lChildren;

    if (g_iAllLocked)  //are all clothing and attachements locked?
    {
        sPrompt += "\n all clothes and attachments are currently locked.";
        //skip the LockClothing and the LockAttachment buttons
        lButtons += ["☒ Lock All"];
    }
    else
    {
        lButtons += ["Lock Clothing"];
        lButtons += ["Lock Attachment"];
        lButtons += ["☐ Lock All"];
    }
    if(g_iSmartStrip==TRUE)
    {
        sPrompt += "\nSmartStrip is on.";
        lButtons += SMARTOFF;
    }
    else
    {
        lButtons += SMARTON;
        sPrompt += "\nSmartStrip is off.";
    }
    lButtons+=SMARTHELP;
    g_kMainID = Dialog(kID, sPrompt, lButtons+g_lSubMenus, [UPMENU], 0, iAuth);
}

QueryClothing(key kAv, integer iAuth)
{    //open listener
    g_iListener = llListen(g_iClothRLV, "", g_kWearer, "");
    //start timer
    llSetTimerEvent(g_iRLVTimeOut);
    //send rlvcmd
    llMessageLinked(LINK_SET, RLV_CMD, "getoutfit=" + (string)g_iClothRLV, NULL_KEY);
    g_kMenuUser = kAv;
    g_iMenuAuth = iAuth;
}

ClothingMenu(key kID, string sStr, integer iAuth)
{
    //str looks like 0110100001111
    //loop through CLOTH_POINTS, look at chaClothingr of str for each
    //for each 1, add capitalized button
    string sPrompt = "Select an article of clothing to remove.";
    list lButtons = [];
    integer iStop = llGetListLength(DETACH_CLOTH_POINTS);
    integer n;
    for (n = 0; n < iStop; n++)
    {
        integer iWorn = (integer)llGetSubString(sStr, n, n);
        list item = [llList2String(DETACH_CLOTH_POINTS, n)];
        if (iWorn && llListFindList(g_lLockedItems,item) == -1)
        {
            if (llList2String(item,0)!="xx")
                lButtons += item;
        }
    }
    g_kClothID = Dialog(kID, sPrompt, lButtons, ["Attachments", UPMENU], 0, iAuth);
}

LockMenu(key kID, integer iAuth)
{
    string sPrompt = "Select an article of clothing to un/lock.";
    list lButtons;
    if (llListFindList(g_lLockedItems,[ALL]) == -1)
        lButtons += [UNTICKED+ALL];
    else  lButtons += [TICKED+ALL];

    integer iStop = llGetListLength(LOCK_CLOTH_POINTS);
    integer n;
    for (n = 0; n < iStop; n++)
    {
        string sCloth = llList2String(LOCK_CLOTH_POINTS, n);
        if (llListFindList(g_lLockedItems,[sCloth]) == -1)
            lButtons += [UNTICKED+sCloth];
        else  lButtons += [TICKED+sCloth];
    }
    g_kLockID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

QueryAttachments(key kAv, integer iAuth)
{    //open listener
    g_iListener = llListen(g_iAttachRLV, "", g_kWearer, "");
    //start timer
    llSetTimerEvent(g_iRLVTimeOut);
    //send rlvcmd
    llMessageLinked(LINK_SET, RLV_CMD, "getattach=" + (string)g_iAttachRLV, NULL_KEY);
    g_kMenuUser = kAv;
    g_iMenuAuth = iAuth;
}

LockAttachmentMenu(key kID, integer iAuth)
{
    string sPrompt = "Select an attachment to un/lock.";
    list lButtons;

    //put tick marks next to locked things
    integer iStop = llGetListLength(ATTACH_POINTS);
    integer n;
    for (n = 1; n < iStop; n++) //starting at 1 as "None" cannot be locked
    {
        string sAttach = llList2String(ATTACH_POINTS, n);
        if (llListFindList(g_lLockedAttach,[sAttach]) == -1)
            lButtons += [UNTICKED+sAttach];
        else  lButtons += [TICKED+sAttach];
    }
    g_kLockAttachID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

DetachMenu(key kID, string sStr, integer iAuth)
{

    //remember not to add button for current object
    //str looks like 0110100001111
    //loop through CLOTH_POINTS, look at char of str for each
    //for each 1, add capitalized button
    string sPrompt = "Select an attachment to remove.";

    //prevent detaching the collar itself
    integer myattachpoint = llGetAttached();

    list lButtons;
    integer iStop = llGetListLength(ATTACH_POINTS);
    integer n;
    for (n = 0; n < iStop; n++)
    {
        if (n != myattachpoint)
        {
            integer iWorn = (integer)llGetSubString(sStr, n, n);
            if (iWorn)
            {
                lButtons += [llList2String(ATTACH_POINTS, n)];
            }
        }
    }
    g_kAttachID = Dialog(kID, sPrompt, lButtons, ["Clothing", UPMENU], 0, iAuth);
}

UpdateSettings()
{    //build one big string from the settings list
    //llOwnerSay("TP settings: " + llDumpList2String(g_lSettings, ","));
    integer iSettingsLength = llGetListLength(g_lSettings);
    if (iSettingsLength > 0)
    {
        g_lLockedItems=[];
        g_lLockedAttach=[];
        integer n;
        list lNewList;
        for (n = 0; n < iSettingsLength; n = n + 2)
        {
            list sOption=llParseString2List(llList2String(g_lSettings, n),[":"],[]);
            string sValue=llList2String(g_lSettings, n + 1);
            //Debug(llList2String(g_lSettings, n) + "=" + sValue);
            lNewList += [llList2String(g_lSettings, n) + "=" + llList2String(g_lSettings, n + 1)];
            if (llGetListLength(sOption)==1 && llList2String(sOption,0)=="remoutfit")
            {
                if (!~llListFindList(g_lLockedItems, [ALL])) g_lLockedItems += [ALL];
            }
            else if (llGetListLength(sOption)==2 && ~llSubStringIndex(llList2String(sOption, 0), "outfit"))
            {
                if (!~llListFindList(g_lLockedItems, [llList2String(sOption, 1)]))
                    g_lLockedItems += [llList2String(sOption,1)];
            }
            else if (llGetListLength(sOption)==2 && ~llSubStringIndex(llList2String(sOption, 0), "tach"))
            {
                if (!~llListFindList(g_lLockedAttach, [llList2String(sOption,1)]))
                    g_lLockedAttach += [llList2String(sOption,1)];
            }
        }
        //output that string to viewer
        llMessageLinked(LINK_SET, RLV_CMD, llDumpList2String(lNewList, ","), NULL_KEY);
        Debug("Loaded locks: Cloth- " + llList2CSV(g_lLockedItems) + ": Attach- " + llList2CSV(g_lLockedAttach));
    }
}

ClearSettings()
{   //clear settings list
    g_lSettings = [];
    //clear the list of locked items
    g_lLockedItems = [];
    g_lLockedAttach=[];
    SaveLockAllFlag(0);
    //remove tpsettings from DB
    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + "List", "");
    //main RLV script will take care of sending @clear to viewer
}

SaveLockAllFlag(integer iSetting)
{
    if (g_iAllLocked == iSetting)
    {
        return;
    }
    g_iAllLocked = iSetting;
    if(iSetting > 0)
    {
        //save the flag to the database
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "LockAll=Y", "");
    }
    else
    {
        //delete the flag from the database
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + "LockAll", "");
    }
}

DoLockAll(key kID)
{
    llMessageLinked(LINK_SET, RLV_CMD, "addattach=n,remattach=n,remoutfit=n,addoutfit=n", NULL_KEY);
}

DoUnlockAll(key kID)
{
    llMessageLinked(LINK_SET, RLV_CMD, "addattach=y,remattach=y,remoutfit=y,addoutfit=y", NULL_KEY);
}

// returns TRUE if eligible (AUTHED link message number)
integer UserCommand(integer iNum, string sStr, key kID) // here iNum: auth value, sStr: user command, kID: avatar id
{
    if (iNum == COMMAND_EVERYONE) return TRUE;  // No command for people with no privilege in this plugin.
    else if (iNum > COMMAND_EVERYONE || iNum < COMMAND_OWNER) return FALSE; // sanity check
    list lParams = llParseString2List(sStr, [":", "=", " "], []);
    string sCommand = llList2String(lParams, 0);
    //Debug(sStr + " ## " + sCommand);
    if (sStr == "menu " + g_sSubMenu)
    {//give this plugin's menu to kID
        MainMenu(kID, iNum);
    }
    else if (sCommand == "smartstrip")
    {
        if(iNum==COMMAND_OWNER || iNum == COMMAND_WEARER)
        {
            
            string sOpt=llList2String(lParams,1);
            if(sOpt == "on")
            {
                g_iSmartStrip=TRUE;
                llMessageLinked(LINK_SET,LM_SETTING_SAVE, g_sScript + g_sSmartToken +"=1","");
                
                
            }
            else
            {
                g_iSmartStrip=FALSE;
                llMessageLinked(LINK_SET,LM_SETTING_DELETE, g_sScript + g_sSmartToken,"");

            }
        }
        else Notify(kID,"This requires a properly set-up outfit, only wearer or owner can turn it on.", FALSE);
    }
    else if (sCommand == "strip")
    {
        string sOpt=llList2String(lParams,1);
        if(sOpt=="all")
        {
           
           if(g_iSmartStrip==TRUE)
            {
                integer x=14; //let's not strip tattoos and physics layers;
                while(x)
                {
                    if(x==13) x=9; //skip hair,skin,shape,eyes
                    --x;
                    string sItem=llToLower(llList2String(DETACH_CLOTH_POINTS,x));
                    llMessageLinked(LINK_SET, RLV_CMD, "detachallthis:"+ sItem +"=force",NULL_KEY);
                    
                 }
            }
           
           llMessageLinked(LINK_SET, RLV_CMD,  "remoutfit=force", NULL_KEY);
            return TRUE;
        }
        sOpt = llToLower(sOpt);
        string test=llToUpper(llGetSubString(sOpt,0,0))+llGetSubString(sOpt,1,-1);
        if(llListFindList(DETACH_CLOTH_POINTS,[test])==-1) return FALSE;
        //send the RLV command to remove it.
        if(g_iSmartStrip==TRUE) llMessageLinked(LINK_SET, RLV_CMD , "detachallthis:" + sOpt + "=force", NULL_KEY);
        llMessageLinked(LINK_SET, RLV_CMD,  "remoutfit:" + sOpt + "=force", NULL_KEY); //yes, this isn't an else. We do it in case the item isn't in #RLV.
    }
        
    else if (llListFindList(g_lRLVcmds, [sCommand]) != -1)
    {    //we've received an RLV command that we control.  only execute if not sub
        if (iNum == COMMAND_WEARER)
        {
            llOwnerSay("Sorry, but RLV commands may only be given by owner, secowner, or group (if set).");
        }
        else
        {
            llMessageLinked(LINK_SET, RLV_CMD, sStr, NULL_KEY);
            string sOption = llList2String(llParseString2List(sStr, ["="], []), 0);
            string sParam = llList2String(llParseString2List(sStr, ["="], []), 1);
            integer iIndex = llListFindList(g_lSettings, [sOption]);
            string opt1 = llList2String(llParseString2List(sOption, [":"], []), 0);
            string opt2 = llList2String(llParseString2List(sOption, [":"], []), 1);
            if (sParam == "n")
            {
                if (iIndex == -1)
                {   //we don't alread have this exact setting.  add it
                    g_lSettings += [sOption, sParam];
                }
                else
                {   //we already have a setting for this option.  update it.
                    g_lSettings = llListReplaceList(g_lSettings, [sOption, sParam], iIndex, iIndex + 1);
                }
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "List=" + llDumpList2String(g_lSettings, ","), "");
            }
            else if (sParam == "y")
            {
                if (iIndex != -1)
                {   //we already have a setting for this option.  remove it.
                    g_lSettings = llDeleteSubList(g_lSettings, iIndex, iIndex + 1);
                }
                if (llGetListLength(g_lSettings)>0)
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "List=" + llDumpList2String(g_lSettings, ","), "");
                else
                    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + "List", "");
            }
        }
    }
    else if (sStr == "lockclothingmenu")
    {
        if (!g_iRLVOn)
        {
            Notify(kID, "RLV features are now disabled in this " + CTYPE + ". You can enable those in RLV submenu. Opening it now.", FALSE);
            llMessageLinked(LINK_SET, iNum, "menu RLV", kID);
            return TRUE;
        }
        LockMenu(kID, iNum);
    }
    else if (sStr == "lockattachmentmenu")
    {
        if (!g_iRLVOn)
        {
            Notify(kID, "RLV features are now disabled in this " + CTYPE + ". You can enable those in RLV submenu. Opening it now.", FALSE);
            llMessageLinked(LINK_SET, iNum, "menu RLV", kID);
            return TRUE;
        }
        LockAttachmentMenu(kID, iNum);
    }
    else  if (llGetSubString(sStr, 0, 11) == "lockclothing")            {
        string sMessage = llGetSubString(sStr, 13, -1);
        if (iNum == COMMAND_WEARER)
        {
            Notify(kID, "Sorry you need owner privileges for locking clothes.", FALSE);
        }
        else if (sMessage==ALL||sStr== "lockclothing")
        {
            g_lLockedItems += [ALL];
            Notify(kID, g_sWearerName+"'s clothing has been locked.", TRUE);
            llMessageLinked(LINK_SET, iNum,  "remoutfit=n", kID);
            llMessageLinked(LINK_SET, iNum,  "addoutfit=n", kID);
        }
        else if (llListFindList(LOCK_CLOTH_POINTS,[sMessage])!=-1)
        {
            g_lLockedItems += sMessage;
            Notify(kID, g_sWearerName+"'s "+sMessage+" has been locked.", TRUE);
            llMessageLinked(LINK_SET, iNum,  "remoutfit:" + sMessage + "=n", kID);
            llMessageLinked(LINK_SET, iNum,  "addoutfit:" + sMessage + "=n", kID);
        }
        else Notify(kID, "Sorry you must either specify a cloth name or not use a parameter (which locks all the clothing layers).", FALSE);
    }
    else if (llGetSubString(sStr, 0, 13) == "unlockclothing")
    {
        if (iNum == COMMAND_WEARER)
        {
            Notify(kID, "Sorry you need owner privileges for unlocking clothes.", FALSE);
        }
        else
        {
            string sMessage = llGetSubString(sStr, 15, -1);
            if (sMessage==ALL||sStr=="unlockclothing")
            {
                llMessageLinked(LINK_SET, iNum,  "remoutfit=y", kID);
                llMessageLinked(LINK_SET, iNum,  "addoutfit=y", kID);
                Notify(kID, g_sWearerName+"'s clothing has been unlocked.", TRUE);
                integer iIndex = llListFindList(g_lLockedItems,[ALL]);
                if (iIndex!=-1) g_lLockedItems = llDeleteSubList(g_lLockedItems,iIndex,iIndex);
            }
            else
            {
                llMessageLinked(LINK_SET, iNum,  "remoutfit:" + sMessage + "=y", kID);
                llMessageLinked(LINK_SET, iNum,  "addoutfit:" + sMessage + "=y", kID);
                Notify(kID, g_sWearerName+"'s "+sMessage+" has been unlocked.", TRUE);
                integer iIndex = llListFindList(g_lLockedItems,[sMessage]);
                if (iIndex!=-1) g_lLockedItems = llDeleteSubList(g_lLockedItems,iIndex,iIndex);
            }
        }
    }
    else  if (llGetSubString(sStr, 0, 13) == "lockattachment")
    {
        string sPoint = llGetSubString(sStr, 15, -1);

        if (iNum == COMMAND_WEARER)
        {
            Notify(kID, "Sorry you need owner privileges for locking attachments.", FALSE);
        }
        else if (llListFindList(ATTACH_POINTS ,[sPoint])!=-1)
        {
            if (llListFindList(g_lLockedAttach, [sPoint]) == -1) g_lLockedAttach += [sPoint];
            Notify(kID, g_sWearerName+"'s "+sPoint+" attachment point is now locked.", TRUE);
            llMessageLinked(LINK_SET, iNum,  "detach:" + sPoint + "=n", kID);
        }
        else
        {
            Notify(kID, "Sorry you must either specify a attachment name.", FALSE);
        }
    }
    else  if (sStr == "lockall")
    {
        if (iNum == COMMAND_WEARER)
        {
            Notify(kID, "Sorry you need owner privileges for locking attachments.", FALSE);
        }
        else
        {
            DoLockAll(kID); //lock all clothes and attachment points
            SaveLockAllFlag(1);
            Notify(kID, g_sWearerName+"'s clothing and attachements have been locked.", TRUE);
        }
    }
    else  if (sStr == "unlockall")
    {
        if (iNum == COMMAND_WEARER)
        {
            Notify(kID, "Sorry you need owner privileges for unlocking attachments.", FALSE);
        }
        else
        {
            DoUnlockAll(kID); //unlock all clothes and attachment points
            SaveLockAllFlag(0);
            Notify(kID, g_sWearerName+"'s clothing and attachements have been unlocked.", TRUE);
        }
    }
    else if (llGetSubString(sStr, 0, 15) == "unlockattachment")
    {
        if (iNum == COMMAND_WEARER)
        {
            Notify(kID, "Sorry you need owner privileges for unlocking attachments.", FALSE);
        }
        else
        {
            string sMessage = llGetSubString(sStr, 17, -1);
        {
            llMessageLinked(LINK_SET, iNum,  "detach:" + sMessage + "=y", kID);
            Notify(kID, g_sWearerName+"'s "+sMessage+" has been unlocked.", TRUE);
            integer iIndex = llListFindList(g_lLockedAttach,[sMessage]);
            if (iIndex!=-1) g_lLockedAttach = llDeleteSubList(g_lLockedAttach,iIndex,iIndex);
        }
        }
    }
    //else if (sStr == "refreshmenu")
    //{
    //    g_lSubMenus = [];
    //    llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, "");
    //}
    else if (sStr == "undress")
    {
        if (!g_iRLVOn)
        {
            Notify(kID, "RLV features are now disabled in this " + CTYPE + ". You can enable those in RLV submenu. Opening it now.", FALSE);
            llMessageLinked(LINK_SET, iNum, "menu RLV", kID);
            return TRUE;
        }

        MainMenu(kID, iNum);
    }
    else if (sStr == "clothing")
    {
        if (!g_iRLVOn)
        {
            Notify(kID, "RLV features are now disabled in this " + CTYPE + ". You can enable those in RLV submenu. Opening it now.", FALSE);
            llMessageLinked(LINK_SET, iNum, "menu RLV", kID);
            return TRUE;
        }
        QueryClothing(kID, iNum);
    }
    else if (sStr == "attachment")
    {
        if (!g_iRLVOn)
        {
            Notify(kID, "RLV features are now disabled in this " + CTYPE + ". You can enable those in RLV submenu. Opening it now.", FALSE);
            llMessageLinked(LINK_SET, iNum, "menu RLV", kID);
            return TRUE;
        }
        QueryAttachments(kID, iNum);
    }
    // rlvoff -> we have to turn the menu off too
    else if (iNum>=COMMAND_OWNER && sStr=="rlvoff") g_iRLVOn=FALSE;
    return TRUE;
}

default
{
    state_entry()
    {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_kWearer = llGetOwner();
        g_sWearerName = llKey2Name(g_kWearer);
        //llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, "");
        //llSleep(1.0);
        //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        //the command was given by either owner, secowner, group member, or wearer
        if (UserCommand(iNum, sStr, kID)) return;
        // rlvoff -> we have to turn the menu off too
        else if (iNum == RLV_OFF) g_iRLVOn=FALSE;
        // rlvon -> we have to turn the menu on again
        else if (iNum == RLV_ON) g_iRLVOn=TRUE;
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            g_lSubMenus = []; //flush submenu buttons
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, "");
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {   //this is tricky since our db value contains equals signs
            //split string on both comma and equals sign
            //first see if this is the token we care about
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sScript)
            {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "LockAll")
                {
                    g_iAllLocked = 1;
                    DoLockAll(kID);
                }
                else if (sToken == "List")
                {
                    g_lSettings = llParseString2List(sValue, [","], []);
                    UpdateSettings();
                }
                else if (sToken == g_sSmartToken)
                {
                    g_iSmartStrip=TRUE;
                }
            }
            else if (sToken == "Global_CType") CTYPE = sValue;
        }
        else if (iNum == RLV_REFRESH)
        {//rlvmain just started up.  Tell it about our current restrictions
            g_iRLVOn = TRUE;
            if(g_iAllLocked > 0)       //is everything locked?
                DoLockAll(kID);  //lock everything on a RLV_REFRESH

            UpdateSettings();
        }
        else if (iNum == RLV_CLEAR)
        {   //clear db and local settings list
            ClearSettings();
        }
        else if (iNum == MENUNAME_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParams, 0)==g_sSubMenu)
            {
                string child = llList2String(lParams, 1);
                //only add submenu if not already present
                if (llListFindList(g_lSubMenus, [child]) == -1)
                {
                    g_lSubMenus += [child];
                    g_lSubMenus = llListSort(g_lSubMenus, 1, TRUE);
                }
            }
        }
        else if (iNum == MENUNAME_REMOVE)
        {
            //sStr should be in form of parentmenu|childmenu
            list lParams = llParseString2List(sStr, ["|"], []);
            string child = llList2String(lParams, 1);
            if (llList2String(lParams, 0)==g_sSubMenu)
            {
                integer iIndex = llListFindList(g_lSubMenus, [child]);
                //only remove if it's there
                if (iIndex != -1)
                {
                    g_lSubMenus = llDeleteSubList(g_lSubMenus, iIndex, iIndex);
                }
            }
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (llListFindList([g_kMainID, g_kClothID, g_kAttachID, g_kLockID, g_kLockAttachID], [kID]) != -1)
            {//it's one of our menus
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (kID == g_kMainID)
                {
                    if (sMessage == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    else if (sMessage == "Rem Clothing") QueryClothing(kAv, iAuth);
                    else if (sMessage == "Rem Attachment") QueryAttachments(kAv, iAuth);
                    else if (sMessage == "Lock Clothing") LockMenu(kAv, iAuth);
                    else if (sMessage == "Lock Attachment") LockAttachmentMenu(kAv, iAuth);
                    else if (sMessage == "☐ Lock All") { UserCommand(iAuth, "lockall", kAv); MainMenu(kAv, iAuth); }
                    else if (sMessage == "☒ Lock All") { UserCommand(iAuth, "unlockall", kAv); MainMenu(kAv, iAuth); }
                    else if (sMessage == SMARTON) { UserCommand(iAuth, "smartstrip on",kAv); MainMenu(kAv, iAuth);}
                    else if (sMessage == SMARTOFF) { UserCommand(iAuth, "smartstrip off",kAv); MainMenu(kAv, iAuth);}
                    else if (sMessage == "Help") { llGiveInventory(kAv,g_sSmartHelpCard); MainMenu(kAv, iAuth);}
                    else if (llListFindList(g_lSubMenus,[sMessage]) != -1)
                    {
                        llMessageLinked(LINK_SET, iAuth, "menu " + sMessage, kAv);
                    }
                    else
                    {
                        //something went horribly wrong.  We got a command that we can't find in the list
                    }
                }
                else if (kID == g_kClothID)
                {
                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else if (sMessage == "Attachments") QueryAttachments(kAv, iAuth);
                    else if (sMessage == ALL) 
                    // SA:Â we can count ourselves lucky that all people who can see the menu have sufficient privileges for remoutfit commands!
                    //    Note for people looking for the auth check: it would have been here, look no further!
                    { //send the RLV command to remove it.
                    
                        UserCommand(iAuth,"strip all",kAv); //See stuff in UserCommand. If we use smartstrip for all, then we'd jump to that here to save duplication, but otherwise it's a single LM, better to do it here than hit UserCommand.
                                            
                       // llMessageLinked(LINK_SET, RLV_CMD,  "remoutfit=force", NULL_KEY);
                        //Return menu
                        //sleep fof a sec to let things detach
                        llSleep(0.5);
                        QueryClothing(kAv, iAuth);
                    }
                    else 
                    {
                        UserCommand(iAuth,"strip "+sMessage,kAv);
                        llSleep(0.5);
                        QueryClothing(kAv, iAuth);
                    }
                        
                    /* Moving this to UserCommand to allow "strip" chat command
                    else
                    { //we got a cloth point.
                        sMessage = llToLower(sMessage);
                        //send the RLV command to remove it.
                        if(kAv==g_kSmartUser || g_iSmartStrip==TRUE){
                        llMessageLinked(LINK_SET, RLV_CMD , "detachallthis:" + sMessage + "=force", NULL_KEY);}
                        llMessageLinked(LINK_SET, RLV_CMD,  "remoutfit:" + sMessage + "=force", NULL_KEY);
                        //Return menu
                        //sleep fof a sec to let things detach
                        llSleep(0.5);
                        QueryClothing(kAv, iAuth);
                    }
                    */
                }
                else if (kID == g_kAttachID)
                {
                    if (sMessage == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu " + g_sSubMenu, kAv);
                    else if (sMessage == "Clothing") QueryClothing(kAv, iAuth);
                    else //SA: same remark here, people who are able to get the menu happen to be the ones who have the permission to detach
                    {    //we got an attach point.  send a message to detach
                        sMessage = llToLower(sMessage);
                        //send the RLV command to remove it.
                        llMessageLinked(LINK_SET, RLV_CMD,  "detach:" + sMessage + "=force", NULL_KEY);
                        //sleep for a sec to let tihngs detach
                        llSleep(0.5);
                        //Return menu
                        g_kMenuUser = kAv;
                        QueryAttachments(kAv, iAuth);
                    }
                }
                else if (kID == g_kLockID)
                {
                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else
                    { //we got a cloth point.
                        string cstate = llGetSubString(sMessage,0,llStringLength(TICKED) - 1);
                        sMessage=llGetSubString(sMessage,llStringLength(TICKED),-1);
                        if (cstate==UNTICKED)
                        {
                            UserCommand(iAuth, "lockclothing "+sMessage, kAv);
                        }
                        else if (cstate==TICKED)
                        {
                            UserCommand(iAuth, "unlockclothing "+sMessage, kAv);
                        }
                        LockMenu(kAv, iAuth);
                    }
                }
                else if (kID == g_kLockAttachID)
                {
                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else
                    { //we got a cloth point.
                        string cstate = llGetSubString(sMessage,0,llStringLength(TICKED) - 1);
                        sMessage=llGetSubString(sMessage,llStringLength(TICKED),-1);
                        if (cstate==UNTICKED)
                        {
                            UserCommand(iAuth, "lockattachment "+sMessage, kAv);
                        }
                        else if (cstate==TICKED)
                        {
                            UserCommand(iAuth, "unlockattachment "+sMessage, kAv);
                        }
                        LockAttachmentMenu(kAv, iAuth);
                    }
                }
            }
        }
    }

    listen(integer iChan, string sName, key kID, string sMessage)
    {
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
        if (iChan == g_iClothRLV)
        {   //llOwnerSay(sMessage);
            ClothingMenu(g_kMenuUser, sMessage, g_iMenuAuth);
        }
        else if (iChan == g_iAttachRLV)
        {
            DetachMenu(g_kMenuUser, sMessage, g_iMenuAuth);
        }
    }

    timer()
    {//stil needed for rlv listen timeouts, though not dialog timeouts anymore
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
    }

    on_rez(integer iParam)
    {
        llResetScript();
    }
}
