/*
** Copyright (c) 2002 D. Richard Hipp
**
** This program is free software; you can redistribute it and/or
** modify it under the terms of the GNU General Public
** License as published by the Free Software Foundation; either
** version 2 of the License, or (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
** General Public License for more details.
**
** You should have received a copy of the GNU General Public
** License along with this library; if not, write to the
** Free Software Foundation, Inc., 59 Temple Place - Suite 330,
** Boston, MA  02111-1307, USA.
**
** Author contact information:
**   drh@hwaci.com
**   http://www.hwaci.com/drh/
**
** 简体中文翻译: 周劲羽 (zjy@cnpack.org) 2003-11-09
**
*******************************************************************************
**
** This file contains code used to generate web pages for
** processing trouble and enhancement tickets.
*/
#include "config.h"
#include "ticket.h"
#include <time.h>

extern time_t parse_time(const char *zTime);
/*
** If the "notify" configuration parameter exists in the CONFIG
** table and is not an empty string, then make various % substitutions
** on that string and execute the result.
*/
void ticket_notify(int tn, int first_change, int last_change, int atn){
  const char *zNotify;
  char *zCmd;
  int i, j, c;
  int cmdSize;
  int cnt[128];
  const char *azSubst[128];

  static const struct { int key; char *zColumn; } aKeys[] = {
      { 'a',  "assignedto"  },
      /* A - e-mail address of assignedto person */
      { 'c',  "contact"     },
      { 'd',  "description" },
      /* D - description, HTML formatted */
      /* f - First TKTCHNG rowid of change set; zero if new record */
      /* h = attacHment number if change is a new attachment; zero otherwise */
      /* l - Last TKTCHNG rowid of change set; zero if new record */
      /* n - ticket number */
      /* p - project name  */
      { 'r',  "remarks"     },
      /* R - remarks, HTML formatted */
      { 's',  "status"      },
      { 't',  "title"       },
      /* u - current user  */
      { 'w',  "owner"       },
      { 'y',  "type"        },
      { '1',  "extra1"        },
      { '2',  "extra2"        },
      { '3',  "extra3"        },
      { '4',  "extra4"        },
      { '5',  "extra5"        },
  };

  if( !db_exists("SELECT tn FROM ticket WHERE tn=%d",tn) ){
    return;
  }

  zNotify = db_config("notify",0);
  if( zNotify==0 || zNotify[0]==0 ) return;
  memset(cnt, 0, sizeof(cnt));
  memset(azSubst, 0, sizeof(azSubst));
  for(i=0; zNotify[i]; i++){
    if( zNotify[i]=='%' ){
      c = zNotify[i+1] & 0x7f;
      cnt[c&0x7f]++;
    }
  }
  if( cnt['n']>0 ){
    azSubst['n'] = mprintf("%d", tn);
  }
  if( cnt['f']>0 ){
    azSubst['f'] = mprintf("%d", first_change);
  }
  if( cnt['h']>0 ){
    azSubst['h'] = mprintf("%d", atn);
  }
  if( cnt['l']>0 ){
    azSubst['l'] = mprintf("%d", last_change);
  }
  if( cnt['u']>0 ){
    azSubst['u'] = mprintf("%s", g.zUser);
  }
  if( cnt['p']>0 ){
    azSubst['p'] = mprintf("%s", g.zName);
  }
  if( cnt['D']>0 ){
    /* ensure we grab a description */
    cnt['d']++;
  }
  if( cnt['R']>0 ){
    /* ensure we grab remarks */
    cnt['r']++;
  }
  if( cnt['A']>0 ){
    azSubst['A'] =
      db_short_query("SELECT user.email FROM ticket, user "
                     "WHERE ticket.tn=%d and ticket.assignedto=user.id", tn);
  }
  for(i=0; i<sizeof(aKeys)/sizeof(aKeys[0]); i++){
    c = aKeys[i].key;
    if( cnt[c]>0 ){
      azSubst[c] =
        db_short_query("SELECT %s FROM ticket WHERE tn=%d",
                       aKeys[i].zColumn, tn);
    }
  }
  if( cnt['c']>0 && azSubst['c']==0 && azSubst['c'][0]==0 ){
    azSubst['c'] = 
      db_short_query("SELECT user.email FROM ticket, user "
                     "WHERE ticket.tn=%d and ticket.owner=user.id", tn);
  }
  if( cnt['D'] ){
    azSubst['D'] = format_formatted( azSubst['d'] );
    cnt['d']--;
  }
  if( cnt['R'] ){
    azSubst['R'] = format_formatted( azSubst['r'] );
    cnt['r']--;
  }

  /* Sanitize the strings to be substituted by removing any single-quotes
  ** and backslashes.
  **
  ** That way, the notify command can contains strings like '%d' or '%r'
  ** (surrounded by quotes) and a hostile user cannot insert arbitrary
  ** shell commands.  Also figure out how much space is needed to hold
  ** the string after substitutes occur.
  */
  cmdSize = strlen(zNotify)+1;
  for(i=0; i<sizeof(azSubst)/sizeof(azSubst[0]); i++){
    if( azSubst[i]==0 || cnt[i]<=0 ) continue;
    azSubst[i] = quotable_string(azSubst[i]);
    cmdSize += cnt[i]*strlen(azSubst[i]);
  }

  zCmd = malloc( cmdSize + 1 );
  if( zCmd==0 ) return;
  for(i=j=0; zNotify[i]; i++){
    if( zNotify[i]=='%' && (c = zNotify[i+1]&0x7f)!=0 && azSubst[c]!=0 ){
      int k;
      const char *z = azSubst[c];
      for(k=0; z[k]; k++){ zCmd[j++] = z[k]; }
      i++;
    }else{
      zCmd[j++] = zNotify[i];
    }
  }
  zCmd[j] = 0;
  assert( j<=cmdSize );
  system(zCmd);
  free(zCmd);
}

/*
** Adds all appropriate action bar links for ticket tools
*/
static void add_tkt_tools(
  const char *zExcept,
  int tn
){
  int i;
  char *zLink;
  char **azTools;
  db_add_functions();
  azTools = db_query("SELECT tool.name FROM tool,user "
                     "WHERE tool.object='tkt' AND user.id='%q' "
                     "      AND cap_and(tool.perms,user.capabilities)!=''",
                     g.zUser);

  for(i=0; azTools[i]; i++){
    if( zExcept && 0==strcmp(zExcept,azTools[i]) ) continue;

    zLink = mprintf("tkttool?t=%T&tn=%d", azTools[i], tn);
    common_add_action_item(zLink, azTools[i]);
  }
}

/*
** WEBPAGE: /tkttool
**
** Execute an external tool on a given ticket
*/
void tkttool(void){
  int tn = atoi(PD("tn","0"));
  const char *zTool = P("t");
  char *zAction;
  const char *azSubst[32];
  int n = 0;

  if( tn==0 || zTool==0 ) cgi_redirect("index");

  login_check_credentials();
  if( !g.okRead ){ login_needed(); return; }
  throttle(1,0);
  history_update(0);

  zAction = db_short_query("SELECT command FROM tool "
                           "WHERE name='%q'", zTool);
  if( zAction==0 || zAction[0]==0 ){
    cgi_redirect(mprintf("tktview?tn=%d",tn));
  }

  common_standard_menu(0, "search?t=1");
  common_add_action_item(mprintf("tktview?tn=%d", tn), "查看");
  common_add_action_item(mprintf("tkthistory?tn=%d", tn), "历史");
  add_tkt_tools(zTool,tn);

  common_header("#%d: %h", tn, zTool);

  azSubst[n++] = "TN";
  azSubst[n++] = mprintf("%d",tn);
  azSubst[n++] = 0;

  n = execute_tool(zTool,zAction,0,azSubst);
  free(zAction);
  if( n<=0 ){
    cgi_redirect(mprintf("tktview?tn=%d", tn));
  }
  common_footer();
}

/*
** WEBPAGE: /tktnew
**
** A web-page for entering a new ticket.
*/
void ticket_new(void){
  const char *zTitle = trim_string(PD("t",""));
  const char *zType = P("y");
  const char *zVers = PD("v","");
  const char *zDesc = remove_blank_lines(PD("d",""));
  const char *zContact = PD("c","");
  const char *zWho = P("w");
  const char *zSubsys = PD("s","");
  const char *zSev = PD("r",db_config("dflt_severity","1"));
  const char *zPri = PD("p",db_config("dflt_priority","1"));
  const char *zFrom = P("f");
  int maxSummaryLength = atoi(db_config("max_ticket_summary","70"));
  int isPreview = P("preview")!=0;
  int severity, priority;
  char **az;
  char *zErrMsg = 0;
  int i;

  login_check_credentials();
  if( !g.okNewTkt ){
    login_needed();
    return;
  }
  throttle(1,1);
  severity = atoi(zSev);
  priority = atoi(zPri);

  /* user can enter #tn or just tn, and empty is okay too */
  zFrom = extract_integer(zFrom);

  if( zType==0 ){
    zType = db_config("dflt_tkt_type","");
  }
  if( zWho==0 ){
    zWho = db_config("assignto","");
  }
  if( zTitle && strlen(zTitle)>maxSummaryLength ){
    zErrMsg = mprintf("标题不能超过 %d 个字符的长度。",
                      maxSummaryLength);
  }
  if( zErrMsg==0 && zTitle[0] && zType[0] && zDesc[0] && P("submit")
      && (zContact[0] || !g.isAnon) ){
    int tn;
    time_t now;
    const char *zState;

    db_execute("BEGIN");
    az = db_query("SELECT max(tn)+1 FROM ticket");
    tn = atoi(az[0]);
    if( tn<=0 ) tn = 1;
    time(&now);
    zState = db_config("initial_state", "new");
    db_execute(
       "INSERT INTO ticket(tn, type, status, origtime,  changetime, "
       "                   version, assignedto, severity, priority, derivedfrom, "
       "                   subsystem, owner, title, description, contact) "
       "VALUES(%d,'%q','%q',%d,%d,'%q','%q',%d,%d,'%q','%q','%q','%q','%q','%q')",
       tn, zType, zState, now, now, zVers, zWho, severity, priority, zFrom, zSubsys,
       g.zUser, zTitle, zDesc, zContact
    );
    for(i=1; i<=5; i++){
      const char *zVal;
      char zX[3];
      bprintf(zX,sizeof(zX),"x%d",i);
      zVal = P(zX);
      if( zVal && zVal[0] ){
        db_execute("UPDATE ticket SET extra%d='%q' WHERE tn=%d", i, zVal, tn);
      }
    }
    db_execute("COMMIT");
    ticket_notify(tn, 0, 0, 0);
    cgi_redirect(mprintf("tktview?tn=%d",tn));
    return;
  }else if( P("submit") ){
    if( zTitle[0]==0 ){
      zErrMsg = "请输入标题。";
    }else if( zDesc[0]==0 ){
      zErrMsg = "请输入描述信息。";
    }else if( zContact[0]==0 && g.isAnon ){
      zErrMsg = "请输入联系方式。";
    }
  }

  common_standard_menu("tktnew", 0);
  common_add_help_item("CvstracTicket");
  common_add_action_item( "index", "取消");
  common_header("创建新的任务单");
  if( zErrMsg ){
    @ <blockquote class="error">
    @ %h(zErrMsg)
    @ </blockquote>
  }
  @ <form action="%T(g.zPath)" method="POST">
  @ <table cellpadding="5">
  @
  @ <tr>
  @ <td colspan=2>
  @ 输入一行关于该问题的摘要信息:<br>
  @ <input type="text" name="t" size=70
  @     maxlength=%d(maxSummaryLength) value="%h(zTitle)">
  @ </td>
  @ </tr>
  @
  @ <tr>
  @ <td align="right">类型:
  cgi_v_optionmenu2(0, "y", zType, (const char**)db_query(
      "SELECT name, value FROM enums WHERE type='type'"));
  @ </td>
  @ <td>该任务单的类型是什么？</td>
  @ </tr>
  @
  @ <tr>
  @   <td align="right" class="nowrap">
  @     版本号: <input type="text" name="v" value="%h(zVers)" size="10">
  @   </td>
  @   <td>
  @      输入存在该问题的产品版本号及/或 Build
  @      号。
  @   </td>
  @ </tr>
  @
  @ <tr>
  @   <td align="right" class="nowrap">
  @     严重度:
  cgi_optionmenu(0, "r", zSev,
         "1", "1", "2", "2", "3", "3", "4", "4", "5", "5", NULL);
  @   </td>
  @   <td>
  @     该问题有多严重？"1" 表示极其严重的错误导致无法工作。
  @     "2" 表示一个主要的错误但还可以工作。
  @     "3" 表示中等错误。"4" 表示让人厌烦的问题。
  @     "5" 表示一个小问题或是如果能加上最好的功能请求。
  @   </td>
  @ </tr>
  @
  @ <tr>
  @   <td align="right" class="nowrap">
  @     优先级:
  cgi_optionmenu(0, "p", zPri,
         "1", "1", "2", "2", "3", "3", "4", "4", "5", "5", NULL);
  @   </td>
  @   <td>
  @     希望该任务单能多短时间内被解决？
  @     "1" 表示立即解决。
  @     "2" 表示在下一次 Build 时解决。
  @     "3" 表示下一次发布前解决。
  @     "4" 表示在时间允许的时候解决。
  @     "5" 表示时间不确定。
  @   </td>
  @ </tr>
  @
  if( g.okWrite ){
    @ <tr>
    @   <td align="right" class="nowrap">
    @     分配给:
    az = db_query("SELECT id FROM user UNION SELECT '' ORDER BY id");
    cgi_v_optionmenu(0, "w", zWho, (const char **)az);
    db_query_free(az);
    @   </td>
    @   <td>
    @     该问题分配给谁来解决？
    @   </td>
    @ </tr>
    @
    az = db_query("SELECT '', '' UNION ALL "
            "SELECT name, value  FROM enums WHERE type='subsys'");
    if( az[0] && az[1] && az[2] ){
      @ <tr>
      @   <td align="right" class="nowrap">
      @     子系统:
      cgi_v_optionmenu2(4, "s", zSubsys, (const char**)az);
      db_query_free(az);
      @   </td>
      @   <td>
      @     在哪一个部分出现的问题？
      @   </td>
      @ </tr>
    }
  }
  @ <tr>
  @   <td align="right" class="nowrap">
  @     衍生自任务单: <input type="text" name="f" value="%h(zFrom)" size="5">
  @   </td>
  @   <td>
  @      是否与某个已存在的任务单相关？
  @   </td>
  @ </tr>
  if( g.isAnon ){
    @ <tr>
    @   <td align="right" class="nowrap">
    @     联系方式: <input type="text" name="c" value="%h(zContact)" size="20">
    @   </td>
    @   <td>
    @      请输入一个电话号码或邮件地址，当一位开发者对该任务单有
    @      疑问时可以与您联系。您输入的信息
    @      将只能被开发者本人看到，普通用户看
    @      不到该信息。
    @   </td>
    @ </tr>
    @
  }
  for(i=1; i<=5; i++){
    char **az;
    const char *zDesc;
    const char *zName;
    char zX[3];
    char zExName[100];

    bprintf(zExName,sizeof(zExName),"extra%d_desc",i);
    zDesc = db_config(zExName, 0);
    if( zDesc==0 || zDesc[0]==0 ) continue;
    bprintf(zExName,sizeof(zExName),"extra%d_name",i);
    zName = db_config(zExName, 0);
    if( zName==0 || zName[0]==0 ) continue;
    az = db_query("SELECT name, value FROM enums "
                   "WHERE type='extra%d'", i);
    bprintf(zX, sizeof(zX), "x%d", i);
    @ <tr>
    @   <td align="right" class="nowrap">
    @     %h(zName):
    if( az==0 || az[0]==0 ){
      @     <input type="text" name="%h(zX)" value="%h(PD(zX,""))" size="20">
    }else{
      cgi_v_optionmenu2(0, zX, PD(zX,az[0]), (const char**)az);
    }
    @   </td>
    @   <td>
    /* description is already HTML markup */
    @      %s(zDesc)
    @   </td>
    @ </tr>
    @
  }
  @ <tr>
  @   <td colspan="2">
  @     输入关于该问题的详细描述。对代码错误而言，
  @     请保证您提供的这些信息能帮助开发者有效地重现
  @     该问题。尽可能多地提供更详尽的信息。
  @     <a href="#format_hints">格式文本说明</a>。
  @     <br>
  cgi_wikitext("d", 40, zDesc);
  if( isPreview ){
    @     <br>描述信息预览:
    @     <table border=1 cellpadding=15 width="100%%"><tr><td>
    output_formatted(zDesc, 0);
    @     </td></tr></table>
  }
  if( g.okWrite ){
    @     <br>提示: 如果您想要包含关于该任务单的一段大的描述或二进制文件，
    @     您可以在创建该任务单后通过增加附件来
    @     提交。请不要在描述信息中直接粘贴巨大
    @     的描述或截屏图像。
  }
  @   </td>
  @ </tr>
  @ <tr>
  @   <td align="right">
  @     <input type="submit" name="preview" value="预览">
  @   </td>
  @   <td>
  @     预览格式化后的描述信息。
  @   </td>
  @ </tr>
  @ <tr>
  @   <td align="right">
  @     <input type="submit" name="submit" value="提交">
  @   </td>
  @   <td>
  @     在填写完前面的相关信息后，请点击该按钮
  @     以创建新的任务单。
  @   </td>
  @ </tr>
  @ </table>
  @ </form>
  @ <a name="format_hints"></a>
  @ <hr>
  @ <h3>格式文本说明:</h3>
  append_formatting_hints();
  common_footer();
}

/*
** Return TRUE if it is ok to undo a ticket change that occurred at
** chngTime and was made by user zUser.
**
** A ticket change can be undone by:
**
**    *  The Setup user at any time.
**
**    *  By the registered user who made the change within 24 hours of
**       the change.
**
**    *  By the Delete user within 24 hours of the change if the change
**       was made by anonymous.
*/
static int ok_to_undo_change(int chngTime, const char *zUser){
  if( g.okSetup ){
    return 1;
  }
  if( g.isAnon || chngTime<time(0)-86400 ){
    return 0;
  }
  if( strcmp(g.zUser,zUser)==0 ){
    return 1;
  }
  if( g.okDelete && strcmp(zUser,"anonymous")==0 ){
    return 1;
  }
  return 0;
}

/*
** WEBPAGE: /tktundo
**
** A webpage removing a prior edit to a ticket
*/
void ticket_undo(void){
  int tn = 0;
  const char *zUser;
  time_t tm;
  const char *z;
  char **az;
  int i;

  login_check_credentials();
  if( !g.okWrite ){ login_needed(); return; }
  throttle(1,1);
  tn = atoi(PD("tn","-1"));
  zUser = PD("u","");
  tm = atoi(PD("t","0"));
  if( tn<0 || tm==0 || zUser[0]==0 ){ cgi_redirect("index"); return; }
  if( !ok_to_undo_change(tm, zUser) ){
    goto undo_finished;
  }
  if( P("can") ){
    /* user cancelled */
    goto undo_finished;
  }
  if( P("w")==0 ){
    common_standard_menu(0,0);
    common_add_help_item("CvstracTicket");
    common_add_action_item(mprintf("tkthistory?tn=%d",tn), "取消");
    common_header("撤消对任务单的修改？");
    @ <p>如果您确认要撤消对任务单 #%d(tn) 的修改，
    @ 请点击下面的 "确定" 链接。否则，点击 "取消"。</p>
    @ <form method="POST" action="tktundo">
    @ <input type="hidden" name="tn" value="%d(tn)">
    @ <input type="hidden" name="u" value="%t(zUser)">
    @ <input type="hidden" name="t" value="%d(tm)">
    @ <table cellpadding="30">
    @ <tr><td>
    @ <input type="submit" name="w" value="确定">
    @ </td><td>
    @ <input type="submit" name="can" value="取消">
    @ </td></tr>
    @ </table>
    @ </form>
    common_footer();
    return;
  }

  /* Make sure the change we are requested to undo is the vary last
  ** change.
  */
  z = db_short_query("SELECT max(chngtime) FROM tktchng WHERE tn=%d", tn);
  if( z==0 || tm!=atoi(z) ){
    goto undo_finished;
  }

  /* If we get this far, it means the user has confirmed that they
  ** want to undo the last change to the ticket.
  */
  db_execute("BEGIN");
  az = db_query("SELECT fieldid, oldval FROM tktchng "
                "WHERE tn=%d AND user='%q' AND chngtime=%d",
                tn, zUser, tm);
  for(i=0; az[i]; i+=2){
    db_execute("UPDATE ticket SET %s='%q' WHERE tn=%d", az[i], az[i+1], tn);
  }
  db_execute("DELETE FROM tktchng WHERE tn=%d AND user='%q' AND chngtime=%d",
             tn, zUser, tm);
  db_execute("COMMIT");

undo_finished:
  cgi_redirect(mprintf("tkthistory?tn=%d",tn));
}  


/*
** Extract the ticket number and report number from the "tn" query
** parameter.
*/
#if 0 /* NOT USED */
static void extract_codes(int *pTn, int *pRn){
  *pTn = *pRn = 0;
  sscanf(PD("tn",""), "%d,%d", pTn, pRn);
}
#endif

static void output_tkt_chng(char **azChng){
  time_t thisDate;
  struct tm *pTm;
  char zDate[100];
  char zPrefix[200];
  char zSuffix[100];
  char *z;
  const char *zType = (atoi(azChng[5])==0) ? "提交" : "里程碑";

  thisDate = atoi(azChng[0]);
  pTm = localtime(&thisDate);
  strftime(zDate, sizeof(zDate), "%Y-%b-%d %H:%M", pTm);
  if( azChng[2][0] ){
    bprintf(zPrefix, sizeof(zPrefix), "%h [%.20h] 于分支 %.50h: ",
            zType, azChng[1], azChng[2]);
  }else{
    bprintf(zPrefix, sizeof(zPrefix), "%h [%.20h]: ", zType, azChng[1]);
  }
  bprintf(zSuffix, sizeof(zSuffix), " (由 %.30h)", azChng[3]);
  @ <tr><td valign="top" width=160 align="right">%h(zDate)</td>
  @ <td valign="top" width=30 align="center">
  common_icon("dot");
  @ </td>
  @ <td valign="top" align="left"> 
  output_formatted(zPrefix, 0);
  z = azChng[4];
  if( output_trim_message(z, MN_CKIN_MSG, MX_CKIN_MSG) ){
    output_formatted(z, 0);
    @ &nbsp;[...]
  }else{
    output_formatted(z, 0);
  }
  output_formatted(zSuffix, 0);
  @ </td></tr>
}

/*
** WEBPAGE: /tktview
**
** A webpage for viewing the details of a ticket
*/
void ticket_view(void){
  int i, j, nChng;
  int tn = 0, rn = 0;
  char **az;
  char **azChng;
  char **azDrv;
  char *z;
  const char *azExtra[5];
  char zPage[30];
  const char *zTn;
  time_t ttime;
  char zTime[32];
  struct tm *pTm;

  login_check_credentials();
  if( !g.okRead ){ login_needed(); return; }
  throttle(1,0);
  history_update(0);
  zTn = PD("tn","");
  sscanf(zTn, "%d,%d", &tn, &rn);
  if( tn<=0 ){ cgi_redirect("index"); return; }
  bprintf(zPage,sizeof(zPage),"%d",tn);
  common_standard_menu("tktview", "search?t=1");
  if( rn>0 ){
    common_replace_nav_item(mprintf("rptview?rn=%d", rn), "报表");
    common_add_action_item(mprintf("tkthistory?tn=%d,%d", tn, rn), "历史");
  }else{
    common_add_action_item(mprintf("tkthistory?tn=%d", tn), "历史");
  }
  if( g.okWrite ){
    if( rn>0 ){
      common_add_action_item(mprintf("tktedit?tn=%d,%d",tn,rn), "编辑");
    }else{
      common_add_action_item(mprintf("tktedit?tn=%d",tn), "编辑");
    }
    if( attachment_max()>0 ){
      common_add_action_item(mprintf("attach_add?tn=%d",tn), "附件");
    }
  }
  add_tkt_tools(0,tn);
  common_add_help_item("CvstracTicket");

  /* Check to see how many "extra" ticket fields are defined
  */
  azExtra[0] = db_config("extra1_name",0);
  azExtra[1] = db_config("extra2_name",0);
  azExtra[2] = db_config("extra3_name",0);
  azExtra[3] = db_config("extra4_name",0);
  azExtra[4] = db_config("extra5_name",0);

  /* Get the record out of the database.
  */
  db_add_functions();
  az = db_query("SELECT "
                "  type,"               /* 0 */
                "  status,"             /* 1 */
                "  ldate(origtime),"    /* 2 */
                "  ldate(changetime),"  /* 3 */
                "  derivedfrom,"        /* 4 */
                "  version,"            /* 5 */
                "  assignedto,"         /* 6 */
                "  severity,"           /* 7 */
                "  priority,"           /* 8 */
                "  subsystem,"          /* 9 */
                "  owner,"              /* 10 */
                "  title,"              /* 11 */
                "  description,"        /* 12 */
                "  remarks, "           /* 13 */
                "  contact,"            /* 14 */
                "  extra1,"             /* 15 */
                "  extra2,"             /* 16 */
                "  extra3,"             /* 17 */
                "  extra4,"             /* 18 */
                "  extra5 "             /* 19 */
                "FROM ticket WHERE tn=%d", tn);
  if( az[0]==0 ){
    cgi_redirect("index");
    return;
  }
  azChng = db_query(
    "SELECT chng.date, chng.cn, chng.branch, chng.user, chng.message, chng.milestone "
    "FROM xref, chng WHERE xref.tn=%d AND xref.cn=chng.cn "
    "ORDER BY chng.milestone ASC, chng.date DESC", tn);
  azDrv = db_query(
    "SELECT tn,title FROM ticket WHERE derivedfrom=%d", tn);
  common_header("任务单 #%d", tn);
  @ <h2>任务单 #%d(tn): %h(az[11])</h2>
  @ <blockquote>
  output_formatted(az[12], zPage);
  @ </blockquote>
  @
  @ <table align="right" style="margin: 0 10px;" cellpadding=2 border=0>
  @ <tr><td bgcolor="%h(BORDER1)" class="border1">
  @ <table width="100%%" border=0 cellpadding=4 cellspacing=0>
  @ <tr bgcolor="%h(BG1)" class="bkgnd1">
  @ <td valign="top" align="left">
  if( az[13][0]==0 ){
    @ [<a href="tktappend?tn=%h(zTn)">增加备注</a>]
  } else {
    @ [<a href="tktappend?tn=%h(zTn)">追加备注</a>]
  }
  @ </td></tr></table></td></tr></table>
  @ <h3>备注:</h3>
  @ <blockquote>
  output_formatted(az[13], zPage);
  @ </blockquote>

  if( az[13][0]!=0 ){
    @ <table align="right" style="margin: 0 10px;" cellpadding=2 border=0>
    @ <tr><td bgcolor="%h(BORDER1)" class="border1">
    @ <table width="100%%" border=0 cellpadding=4 cellspacing=0>
    @ <tr bgcolor="%h(BG1)" class="bkgnd1">
    @ <td valign="top" align="left">
    @ [<a href="tktappend?tn=%h(zTn)">追加备注</a>]
    @ </td></tr></table></td></tr></table>
    @
  }

  @
  @ <h3>属性:</h3>
  @
  @ <blockquote>
  @ <table>
  @ <tr>
  @   <td align="right">类型:</td>
  @   <td bgcolor="%h(BG3)" class="bkgnd3"><b>%h(az[0])&nbsp;</b></td>
  @ <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  @   <td align="right">版本号:</td>
  @   <td bgcolor="%h(BG3)" class="bkgnd3"><b>%h(az[5])&nbsp;</b></td>
  @ </tr>
  @ <tr>
  @   <td align="right">状态:</td>
  @   <td bgcolor="%h(BG3)" class="bkgnd3"><b>%h(az[1])</b></td>
  @ <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  @   <td align="right">创建时间:</td>
  @   <td bgcolor="%h(BG3)" class="bkgnd3"><b>%h(az[2])</b></td>
  @ </tr>
  @ <tr>
  @   <td align="right">严重度:</td>
  @   <td bgcolor="%h(BG3)" class="bkgnd3"><b>%h(az[7])&nbsp;</b></td>
  @ <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  @   <td align="right">更新时间:</td>
  @   <td bgcolor="%h(BG3)" class="bkgnd3"><b>%h(az[3])</b></td>
  @ </tr>
  @ <tr>
  @   <td align="right">优先级:</td>
  @   <td bgcolor="%h(BG3)" class="bkgnd3"><b>%h(az[8])&nbsp;</b></td>
  @ <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  @   <td align="right">子系统:</td>
  @   <td bgcolor="%h(BG3)" class="bkgnd3"><b>%h(az[9])&nbsp;</b></td>
  @ </tr>
  @ <tr>
  @   <td align="right">分配给:</td>
  @   <td bgcolor="%h(BG3)" class="bkgnd3"><b>%h(az[6])&nbsp;</b></td>
  @ <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  @   <td align="right">衍生自任务单:</td>
  @   <td bgcolor="%h(BG3)" class="bkgnd3"><b>
  z = extract_integer(az[4]);
  if( z && z[0] ){
    z = mprintf("#%s",z);
    output_formatted(z,zPage);
  }else{
    @   &nbsp;
  }
  @   </b></td>
  @ </tr>
  @ <tr>
  @   <td align="right">创建人:</td>
  @   <td bgcolor="%h(BG3)" class="bkgnd3"><b>%h(az[10])&nbsp;</b></td>
  if( g.okWrite && !g.isAnon ){
    @ <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
    @   <td align="right">联系方式:</td>
    if( strchr(az[14],'@') ){
      @   <td bgcolor="%h(BG3)" class="bkgnd3"><b><a href="mailto:%h(az[14])">
      @        %h(az[14])</a>&nbsp;</b></td>
    }else{
      @   <td bgcolor="%h(BG3)" class="bkgnd3"><b>%h(az[14])&nbsp;</b></td>
    }
    @ </tr>
    j = 0;
  } else {
    j = 1;
  }
  for(i=0; i<5; i++){
    if( azExtra[i]==0 ) continue;
    if( j==0 ){
      @ <tr>
    }else{
      @ <td></td>
    }
    @   <td align="right">%h(azExtra[i]):</td>
    @   <td bgcolor="%h(BG3)" class="bkgnd3"><b>%h(az[15+i])&nbsp;</b></td>
    if( j==0 ){
      j = 1;
    }else{
      @ </tr>
      j = 0;
    }
  }
  if( j==1 ){
    @ </tr>
  }
  @ </table>
  @ </blockquote>
  if( azDrv[0] ){
    int i;
    @ <h3>衍生自任务单:</h3>
    @ <table cellspacing=0 border=0 cellpadding=0>
    for(i=0; azDrv[i]; i+=2){
      @ <tr><td valign="top" width=160 align="right">
      z = mprintf("#%s",azDrv[i]);
      output_formatted(z,zPage);
      @ </td>
      @ <td valign="center" width=30 align="center">
      common_icon("ptr1");
      @ </td>
      @ <td valign="top" align="left">
      output_formatted(azDrv[i+1],0);
      @ </td></tr>
    }
    @ </table>
  }
  nChng = 0;
  if( azChng[0] && azChng[5] && atoi(azChng[5])==0 ){
    int i;
    @ <h3>相关的 CVS 提交:</h3>
    @ <table cellspacing=0 border=0 cellpadding=0>
    for(i=0; azChng[i]; i+=6){
      /* Milestones are handeld in loop below */
      if( atoi(azChng[i+5]) ) break;

      nChng++;
      output_tkt_chng(&azChng[i]);
    }
    @ </table>
  }
  
  if( azChng[0] && azChng[nChng*6] ){
    int i;
    @ <h3>相关的里程碑:</h3>
    @ <table cellspacing=0 border=0 cellpadding=0>
    for(i=nChng*6; azChng[i]; i+=6){
      output_tkt_chng(&azChng[i]);
    }
    @ </table>
  }
  attachment_html(zPage,"<h3>附件:</h3>\n<blockquote>","</blockquote>");
  common_footer();
}

/*
** Check to see if the current user is authorized to delete ticket tn.
** Return true if they are and false if not.
**
** Ticket deletion rules:
**
**     * The setup user can delete any ticket at any time.
**
**     * Users other than anonymous with Delete privilege can delete
**       a ticket that was originated by anonymous and has no change
**       by anyone other than anonymous and is less than 24 hours old.
**
**     * Anonymous users can never delete tickets even if they have
**       Delete privilege
*/
static int ok_to_delete_ticket(int tn){
  time_t cutoff = time(0)-86400;
  if( g.okSetup ){
    return 1;
  }
  if( g.isAnon || !g.okDelete ){
    return 0;
  }
  if( db_exists(
     "SELECT 1 FROM ticket"
     " WHERE tn=%d AND (owner!='anonymous' OR origtime<%d)"
     "UNION ALL "
     "SELECT 1 FROM tktchng"
     " WHERE tn=%d AND (user!='anonymous' OR chngtime<%d)",
     tn, cutoff, tn, cutoff)
  ){
    return 0;
  }
  return 1;
}

static int tok_compare(const void *zA_, const void *zB_){
  const char **zA = (const char **)zA_;
  const char **zB = (const char **)zB_;
  return strcmp(*zA,*zB);
}

/*
** Tokenize a string and return it in a newly allocated NULL-terminated
** list. The resulting list is sorted alphabetically.
*/
static char **tokenize_new_line(const char *zString){
  int nTok = 0;
  char **azToks;
  int i, j, k;

  for(i=nTok=0; zString[i]; i++){
    if( !isspace(zString[i]) ){
      nTok++;
      while( zString[i+1] && !isspace(zString[i+1]) ) i++;
    }
  }
  azToks = malloc( sizeof(char *)*(nTok+1) );
  if( azToks==0 ) return NULL;
  for(i=j=0; j<nTok && zString[i]; i++){
    if( !isspace(zString[i]) ){
      k = i+1;
      while( zString[k] && !isspace(zString[k]) ) k++;
      azToks[j++] = mprintf("%.*s",k-i,&zString[i]);
      i = k;
    }
  }
  azToks[j] = 0;

  /* sort the result list. This makes it easy to catch duplicates.
  */
  qsort(azToks, j, sizeof(char*), tok_compare);

  return azToks;
}

/*
** WEBPAGE: /tktedit
**
** A webpage for making changes to a ticket
*/
void ticket_edit(void){
  static struct {
    char *zColumn;     /* Name of column in the database */
    char *zName;       /* Name of corresponding query parameter */
    int preserveSpace; /* Preserve initial spaces in text */
    int numeric;       /* Field is a numeric value */
    const char *zOld;  /* Current value of this field */
    const char *zNew;  /* Value of the query parameter */
  } aParm[] = {
    { "type",         "y", 0, 0, },  /* 0 */
    { "status",       "s", 0, 0, },  /* 1 */
    { "derivedfrom",  "d", 0, 1, },  /* 2 */
    { "version",      "v", 0, 0, },  /* 3 */
    { "assignedto",   "a", 0, 0, },  /* 4 */
    { "severity",     "e", 0, 1, },  /* 5 */
    { "priority",     "p", 0, 0, },  /* 6 */
    { "subsystem",    "m", 0, 0, },  /* 7 */
    { "owner",        "w", 0, 0, },  /* 8 */
    { "title",        "t", 0, 0, },  /* 9 */
    { "description",  "c", 1, 0, },  /* 10 */
    { "remarks",      "r", 1, 0, },  /* 11 */
    { "contact",      "n", 0, 0, },  /* 12 */
    { "extra1",      "x1", 0, 0, },  /* 13 */
    { "extra2",      "x2", 0, 0, },  /* 14 */
    { "extra3",      "x3", 0, 0, },  /* 15 */
    { "extra4",      "x4", 0, 0, },  /* 16 */
    { "extra5",      "x5", 0, 0, },  /* 17 */
  };
  int tn = 0;
  int rn = 0;
  int nField;
  int i, j;
  int cnt;
  int isPreview;
  int maxSummaryLength = atoi(db_config("max_ticket_summary","70"));
  char *zSep;
  char **az;
  const char **azUsers = 0;
  char **azChng = 0;
  char **azMs = 0;
  int nExtra;
  const char *azExtra[5];
  char zPage[30];
  char zSQL[2000];
  char *zErrMsg = 0;
  time_t le = 0;
  time_t te = 0;

  login_check_credentials();
  if( !g.okWrite ){ login_needed(); return; }
  throttle(1,1);
  isPreview = P("pre")!=0;
  sscanf(PD("tn",""), "%d,%d", &tn, &rn);
  if( tn<=0 ){ cgi_redirect("index"); return; }
  bprintf(zPage,sizeof(zPage),"%d",tn);
  history_update(0);

  if( atoi(db_config("safe_ticket_editting","0")) ){
    char *z = db_short_query("SELECT changetime FROM ticket WHERE tn=%d",tn);
    if( z ) te = atoi(z);

    /* If le==0, we won't check for other changes while editting */
    le = atoi(PD("le","0"));
  }

  if( P("del1") && ok_to_delete_ticket(tn) ){
    char *zTitle = db_short_query("SELECT title FROM ticket "
                                  "WHERE tn=%d", tn);
    if( zTitle==0 ) cgi_redirect("index");

    common_add_action_item(mprintf("tktedit?tn=%h",PD("tn","")), "取消");
    common_header("确认删除？");
    @ <form action="tktedit" method="POST">
    @ <p>您将要从数据库中删除任务单
    output_ticket(tn,0);
    @ &nbsp;<strong>%h(zTitle)</strong> 及其所
    @ 有跟踪记录。这是一个无法撤消的操作，所有与该任务单相关的
    @ 记录都将被删除并且无法恢复。</p>
    @
    if( te ){
      @ <input type="hidden" name="le" value="%d(te)">
    }
    @ <input type="hidden" name="tn" value="%h(PD("tn",""))">
    @ <input type="submit" name="del2" value="删除该任务单">
    @ <input type="submit" name="can" value="取消">
    @ </form>
    common_footer();
    return;
  }

  if( P("del2") && ok_to_delete_ticket(tn) ){
    if( le && te > le ){
      common_add_action_item(mprintf("tktview?tn=%d",tn), "取消");
      common_add_action_item(mprintf("tktedit?tn=%d,%d&del1=1", tn, rn),
                             "删除");
      common_header("任务单已变更!");
      @ <p>任务单 #%d(tn) 在您尝试删除时已经被其它人
      @ 修改并提交过了!</p>
      @ <a href="tktedit?tn=%d(tn),%d(rn)&del1=1">重试</a> 或
      @ <a href="tktview?tn=%d(tn),%d(rn)">取消</a>?
      common_footer();
      return;
    }

    db_execute(
       "BEGIN;"
       "DELETE FROM ticket WHERE tn=%d;"
       "DELETE FROM tktchng WHERE tn=%d;"
       "DELETE FROM xref WHERE tn=%d;"
       "DELETE FROM attachment WHERE tn=%d;"
       "COMMIT;", tn, tn, tn, tn);
    if( rn>0 ){
      cgi_redirect(mprintf("rptview?rn=%d",rn));
    }else{
      cgi_redirect("index");
    }
    return;
  }

  /* Check to see how many "extra" ticket fields are defined
  */
  nField = sizeof(aParm)/sizeof(aParm[0]);
  azExtra[0] = db_config("extra1_name",0);
  azExtra[1] = db_config("extra2_name",0);
  azExtra[2] = db_config("extra3_name",0);
  azExtra[3] = db_config("extra4_name",0);
  azExtra[4] = db_config("extra5_name",0);
  for(i=nExtra=0; i<5; i++){
    if( azExtra[i]!=0 ){
      nExtra++;
    }else{
      aParm[13+i].zColumn = 0;
    }
  }

  /* Construct a SELECT statement to extract all information we
  ** need from the ticket table.
  */
  j = 0;
  appendf(zSQL,&j,sizeof(zSQL),"SELECT");
  zSep = " ";
  for(i=0; i<nField; i++){
    appendf(zSQL,&j,sizeof(zSQL), "%s%s", zSep,
            aParm[i].zColumn ? aParm[i].zColumn : "''");
    zSep = ",";
  }
  appendf(zSQL,&j,sizeof(zSQL), " FROM ticket WHERE tn=%d", tn);

  /* Execute the SQL.  Load all existing values into aParm[].zOld.
  */
  az = db_query(zSQL);
  if( az==0 || az[0]==0 ){
    cgi_redirect("index");
    return;
  }
  for(i=0; i<nField; i++){
    if( aParm[i].zColumn==0 ) continue;
    aParm[i].zOld = remove_blank_lines(az[i]);
  }

  /* Find out which fields may need to change due to query parameters.
  ** record the new values in aParm[].zNew.
  */
  for(i=cnt=0; i<nField; i++){
    if( aParm[i].zColumn==0 ){ cnt++; continue; }
    aParm[i].zNew = P(aParm[i].zName);
    if( aParm[i].zNew==0 ){
      aParm[i].zNew = aParm[i].zOld;
      if( g.isAnon && aParm[i].zName[0]=='n' ) cnt++;
    }else if( aParm[i].preserveSpace ){
      aParm[i].zNew = remove_blank_lines(aParm[i].zNew);

      /* Only remarks and description fields (i.e. Wiki fields) have
      ** preserve space set. Perfect place to run through edit
      ** heuristics. If it's not allowed, the change won't go through
      ** since the counter won't match.
      */
      zErrMsg = is_edit_allowed(aParm[i].zOld,aParm[i].zNew);
      if( 0==zErrMsg ){
        cnt++;
      }
    }else if( aParm[i].numeric ){
      aParm[i].zNew = extract_integer(aParm[i].zNew);
      cnt++;
    }else{
      aParm[i].zNew = trim_string(aParm[i].zNew);
      cnt++;
    }
  }

  if( g.okCheckout ){
    if( P("cl") && P("ml") ){
      /* The "cl" query parameter holds a list of integer check-in numbers that
      ** this ticket is associated with.  Convert the string into a list of
      ** tokens. We'll filter out non-integers later.
      */
      azChng = tokenize_new_line(P("cl"));
      azMs = tokenize_new_line(P("ml"));
    }else{
      /*
      ** Probably a new form, so get the info from the database.
      */
      azChng = db_query( "SELECT xref.cn FROM xref, chng "
                         "WHERE xref.cn=chng.cn AND "
                         "       chng.milestone=0 AND xref.tn=%d", tn);

      azMs = db_query( "SELECT xref.cn FROM xref, chng "
                       "WHERE xref.cn=chng.cn AND "
                       "       chng.milestone>0 AND xref.tn=%d", tn);
    }
  }

  /* Update the record in the TICKET table.  Also update the XREF table.
  */
  if( cnt==nField && P("submit")!=0 && (!le || le >= te) ){
    time_t now;
    char **az;
    int first_change;
    int last_change;
    
    time(&now);
    db_execute("BEGIN");
    az = db_query(
        "SELECT MAX(ROWID)+1 FROM tktchng"
    );
    first_change = atoi(az[0]);
    for(i=cnt=0; i<nField; i++){
      if( aParm[i].zColumn==0 ) continue;
      if( strcmp(aParm[i].zOld,aParm[i].zNew)==0 ) continue;
      db_execute("UPDATE ticket SET %s='%q' WHERE tn=%d",
         aParm[i].zColumn, aParm[i].zNew, tn);
      db_execute("INSERT INTO tktchng(tn,user,chngtime,fieldid,oldval,newval) "
          "VALUES(%d,'%q',%d,'%s','%q','%q')",
          tn, g.zUser, now, aParm[i].zColumn, aParm[i].zOld, aParm[i].zNew);
      cnt++;
    }
    az = db_query(
        "SELECT MAX(ROWID) FROM tktchng"
        );
    last_change = atoi(az[0]);
    if( cnt ){
      db_execute("UPDATE ticket SET changetime=%d WHERE tn=%d", now, tn);
    }

    if( g.okCheckout && P("cl") && P("ml") ){
      db_execute("DELETE FROM xref WHERE tn=%d", tn);

      /*
      ** Insert the values into the cross reference table, but only
      ** once (xref could _really_ use a uniqueness constraint).
      */

      if( azChng!=0 ){
        for(i=0; azChng[i]; i++){
          if( is_integer(azChng[i]) && (i==0 || strcmp(azChng[i],azChng[i-1]))){
            db_execute("INSERT INTO xref(tn,cn) "
                       "SELECT %d,cn FROM chng "
                       "       WHERE cn=%d AND milestone=0", 
                       tn, atoi(azChng[i]));
          }
        }
      }
      if( azMs!=0 ){
        for(i=0; azMs[i]; i++){
          if( is_integer(azMs[i]) && (i==0 || strcmp(azMs[i],azMs[i-1]))){
            db_execute("INSERT INTO xref(tn,cn) "
                       "SELECT %d,cn FROM chng "
                       "       WHERE cn=%d AND milestone>0",
                       tn, atoi(azMs[i]));
          }
        }
      }
    }
    db_execute("COMMIT");
    if( cnt ){
      ticket_notify(tn, first_change, last_change, 0);
    }
    if( rn>0 ){
      cgi_redirect(mprintf("rptview?rn=%d",rn));
    }else{
      cgi_redirect(mprintf("tktview?tn=%d,%d",tn,rn));
    }
    return;
  }

  /* Print the header.
  */
  common_add_action_item( mprintf("tktview?tn=%d,%d", tn, rn), "取消");
  if( ok_to_delete_ticket(tn) ){
    common_add_action_item( mprintf("tktedit?tn=%d,%d&del1=1", tn, rn),
                            "删除");
  }
  common_add_help_item("CvstracTicket");
  common_header("编辑任务单 #%d", tn);

  @ <form action="tktedit" method="POST">
  @ 
  @ <input type="hidden" name="tn" value="%d(tn),%d(rn)">
  if( le || te ){
    /* Don't stomp on someone elses edit if they hit submit first. */
    @ <input type="hidden" name="le" value="%d(le ? le : te)">
  }
  @ <span class="nowrap">任务单编号: %d(tn)</span><br>
  if( le && le < te ){
    @ <p class="error">
    @ 任务单 #%d(tn) 在您编辑期间已经被其它人
    @ 修改并提交过了!
    @ </p>
  }

  if( zErrMsg ){
    @ <blockquote class="error">
    @ %h(zErrMsg)
    @ </blockquote>
  }
  @ <span class="nowrap">
  @ 标题: <input type="text" name="t" value="%h(aParm[9].zNew)"
  @   maxlength=%d(maxSummaryLength) size=70>
  @ </span><br>
  @ 
  @ 描述信息:
  @ (<small>参见 <a href="#format_hints">格式文本说明</a></small>)<br>
  cgi_wikitext("c", 40, aParm[10].zNew);
  @ <br>
  if( isPreview ){
    @ <table border=1 cellpadding=15 width="100%%"><tr><td>
    output_formatted(aParm[10].zNew, zPage);
    @ &nbsp;</td></tr></table><br>
  }
  @
  @ 备注:
  @ (<small>参见 <a href="#format_hints">格式文本说明</a></small>)<br>
  cgi_wikitext("r", 40, aParm[11].zNew);
  @ <br>
  if( isPreview ){
    @ <table border=1 cellpadding=15 width="100%%"><tr><td>
    output_formatted(aParm[11].zNew, zPage);
    @ &nbsp;</td></tr></table><br>
  }
  @ 
  @ <span class="nowrap">
  @ 状态:
  cgi_v_optionmenu2(0, "s", aParm[1].zNew, (const char**)db_query(
     "SELECT name, value FROM enums WHERE type='status'"));
  @ </span>
  @ &nbsp;&nbsp;&nbsp;
  @ 
  @ <span class="nowrap">
  @ 类型: 
  cgi_v_optionmenu2(0, "y", aParm[0].zNew, (const char**)db_query(
     "SELECT name, value FROM enums WHERE type='type'"));
  @ </span>
  @ &nbsp;&nbsp;&nbsp;
  @ 
  @ 
  @ <span class="nowrap">
  @ 严重度: 
  cgi_optionmenu(0, "e", aParm[5].zNew,
         "1", "1", "2", "2", "3", "3", "4", "4", "5", "5", NULL);
  @ </span>
  @ &nbsp;&nbsp;&nbsp;
  @ 
  @ <span class="nowrap">
  @ 分配给: 
  azUsers = (const char**)db_query(
              "SELECT id FROM user UNION SELECT '' ORDER BY id");
  cgi_v_optionmenu(0, "a", aParm[4].zNew, azUsers);
  @ </span>
  @ &nbsp;&nbsp;&nbsp;
  @ 
  @ <span class="nowrap">
  @ 子系统:
  cgi_v_optionmenu2(0, "m", aParm[7].zNew, (const char**)db_query(
      "SELECT '','' UNION ALL "
      "SELECT name, value FROM enums WHERE type='subsys'"));
  @ </span>
  @ &nbsp;&nbsp;&nbsp;
  @ 
  @ <span class="nowrap">
  @ 版本号: <input type="text" name="v" value="%h(aParm[3].zNew)" size=10>
  @ </span>
  @ &nbsp;&nbsp;&nbsp;
  @ 
  @ <span class="nowrap">
  @ 衍生自任务单: <input type="text" name="d" value="%h(aParm[2].zNew)" size=10>
  @ </span>
  @ &nbsp;&nbsp;&nbsp;
  @ 
  @ <span class="nowrap">
  @ 优先级:
  cgi_optionmenu(0, "p", aParm[6].zNew,
         "1", "1", "2", "2", "3", "3", "4", "4", "5", "5", NULL);
  @ </span>
  @ &nbsp;&nbsp;&nbsp;
  @ 
  @ <span class="nowrap">
  @ 创建人: 
  cgi_v_optionmenu(0, "w", aParm[8].zNew, azUsers);
  @ </span>
  @ &nbsp;&nbsp;&nbsp;
  @
  if( !g.isAnon ){
    @ <span class="nowrap">
    @ 联系方式: <input type="text" name="n" value="%h(aParm[12].zNew)" size=20>
    @ </span>
    @ &nbsp;&nbsp;&nbsp;
    @
  }
  for(i=0; i<5; i++){
    char **az;
    char zX[3];

    if( azExtra[i]==0 ) continue;
    az = db_query("SELECT name, value FROM enums "
                   "WHERE type='extra%d'", i+1);
    bprintf(zX, sizeof(zX), "x%d", i+1);
    @ <span class="nowrap">
    @ %h(azExtra[i]):
    if( az && az[0] ){
      cgi_v_optionmenu2(0, zX, aParm[13+i].zNew, (const char **)az);
    }else{
      @ <input type="text" name="%h(zX)" value="%h(aParm[13+i].zNew)" size=20>
    }
    db_query_free(az);
    @ </span>
    @ &nbsp;&nbsp;&nbsp;
    @
  }
  if( g.okCheckout ){
    /*
    ** Note that we don't filter the output here. If the user typed in
    ** something bad, they should be able to see it.
    */

    @ <span class="nowrap">
    @ 相关提交:
    @ <input type="text" name="cl" size=70 value="\
    if( azChng!=0 ){
      for(i=0; azChng[i]; i++){
        @ %s(i?" ":"")%h(azChng[i])\
      }
    }
    @ ">
    @ </span>
    @ &nbsp;&nbsp;&nbsp;
    @ <span class="nowrap">
    @ 相关里程碑:
    @ <input type="text" name="ml" size=70 value="\
    if( azMs!=0 ){
      for(i=0; azMs[i]; i++){
        @ %s(i?" ":"")%h(azMs[i])\
      }
    }
    @ ">
    @ </span>
    @ &nbsp;&nbsp;&nbsp;
    @ 
  }
  @ <p align="center">
  @ <input type="submit" name="submit" value="应用修改">
  @ &nbsp;&nbsp;&nbsp;
  @ <input type="submit" name="pre" value="预览描述信息和备注">
  if( ok_to_delete_ticket(tn) ){
    @ &nbsp;&nbsp;&nbsp;
    @ <input type="submit" name="del1" value="删除该任务单">
  }
  @ </p>
  @
  @ </form>
  attachment_html(mprintf("%d",tn),"<h3>附件</h3><blockquote>",
      "</blockquote>");
  @
  @ <a name="format_hints"></a>
  @ <hr>
  @ <h3>格式文本说明:</h3>
  append_formatting_hints();
  common_footer();
}

/*
** WEBPAGE: /tktappend
**
** Append remarks to a ticket
*/
void ticket_append(void){
  int tn, rn;
  char zPage[30];
  int doPreview;
  int doSubmit;
  const char *zText;
  const char *zTn;
  char *zErrMsg = 0;
  char *zTktTitle;
  time_t le = 0;
  time_t te = 0;

  login_check_credentials();
  if( !g.okWrite ){ login_needed(); return; }
  throttle(1,1);
  tn = rn = 0;
  zTn = PD("tn","");
  sscanf(zTn, "%d,%d", &tn, &rn);
  if( tn<=0 ){ cgi_redirect("index"); return; }
  bprintf(zPage,sizeof(zPage),"%d",tn);
  doPreview = P("pre")!=0;
  doSubmit = P("submit")!=0;
  zText = remove_blank_lines(PD("r",""));

  if( atoi(db_config("safe_ticket_editting","0")) ){
    char *z = db_short_query("SELECT changetime FROM ticket WHERE tn=%d",tn);
    if( z ) te = atoi(z);

    /* If le==0, we won't check for other changes while editting */
    le = atoi(PD("le","0"));

    if( le && le<te ) doSubmit = 0;
  }

  if( doSubmit ){
    zErrMsg = is_edit_allowed(0,zText);
    if( zText[0] && 0==zErrMsg ){
      time_t now;
      struct tm *pTm;
      char zDate[200];
      const char *zOrig;
      char *zNew;
      char *zSpacer = " {linebreak}\n";
      char *zHLine = "\n\n----\n";
      char **az;
      int change;
      zOrig = db_short_query("SELECT remarks FROM ticket WHERE tn=%d", tn);
      zOrig = remove_blank_lines(zOrig);
      time(&now);
      pTm = localtime(&now);
      strftime(zDate, sizeof(zDate), "%Y-%b-%d %H:%M:%S", pTm);
      if( isspace(zText[0]) && isspace(zText[1]) ) zSpacer = "\n\n";
      if( zOrig[0]==0 ) zHLine = "";
      zNew = mprintf("%s_%s by %s:_%s%s",
                     zHLine, zDate, g.zUser, zSpacer, zText);
      db_execute(
        "BEGIN;"
        "UPDATE ticket SET remarks='%q%q', changetime=%d WHERE tn=%d;"
        "INSERT INTO tktchng(tn,user,chngtime,fieldid,oldval,newval) "
           "VALUES(%d,'%q',%d,'remarks','%q','%q%q');"
        "COMMIT;",
        zOrig, zNew, now, tn,
        tn, g.zUser, now, zOrig, zOrig, zNew
      );
      az = db_query(
          "SELECT MAX(ROWID) FROM tktchng"
          );
      change = atoi(az[0]);
      ticket_notify(tn, change, change, 0);
      cgi_redirect(mprintf("tktview?tn=%h",zTn));
    }
  }
  zTktTitle = db_short_query("SELECT title FROM ticket WHERE tn=%d", tn);
  
  common_add_help_item("CvstracTicket");
  common_add_action_item( mprintf("tktview?tn=%h", zTn), "取消");
  common_header("追加备注到任务单 #%d", tn);

  if( le && le < te ){
    @ <p class="error">
    @ 任务单 #%d(tn) 在您编辑期间已经被其它人
    @ 修改并提交了!</p>
  }
  if( zErrMsg ){
    @ <blockquote class="error">
    @ %h(zErrMsg)
    @ </blockquote>
  }

  @ <form action="tktappend" method="POST">
  if( le || te ){
    /* Don't stomp on someone elses edit if they hit submit first. */
    @ <input type="hidden" name="le" value="%d(le ? le : te)">
  }
  @ <input type="hidden" name="tn" value="%h(zTn)">
  @ 追加备注到 #%d(tn):
  cgi_href(zTktTitle, 0, 0, 0, 0, 0, "tktview?tn=%d", tn);
  @ &nbsp;
  @ (<small>参见 <a href="#format_hints">格式文本说明</a></small>)<br>
  cgi_wikitext("r", 60, zText);
  @ <br>
  @ <p align="center">
  @ <input type="submit" name="submit" value="应用">
  @ &nbsp;&nbsp;&nbsp;
  @ <input type="submit" name="pre" value="预览">
  @ </p>
  if( doPreview ){
    @ <table border=1 cellpadding=15 width="100%%"><tr><td>
    output_formatted(zText, zPage);
    @ &nbsp;</td></tr></table><br>
  }
  @ 
  @ </form>
  @ <a name="format_hints"></a>
  @ <hr>
  @ <h3>格式文本说明:</h3>
  append_formatting_hints();
  common_footer();
}

/*
** Output a ticket change record. isLast indicates it's the last
** ticket change and _might_ be subject to undo.
*/
static void ticket_change(
  time_t date,        /* date/time of the change */
  int tn,             /* ticket number */
  const char *zUser,  /* user that made the change */
  const char *zField, /* field that changed */
  const char *zOld,   /* old value */
  const char *zNew,   /* new value */
  int isLast          /* non-zero if last ticket change in the history */
){
  struct tm *pTm;
  char zDate[100];
  char zPage[30];

  bprintf(zPage,sizeof(zPage),"%d",tn);

  pTm = localtime(&date);
  strftime(zDate, sizeof(zDate), "%Y-%b-%d %H:%M", pTm);

  @ <li>

  if( strcmp(zField,"description")==0 || strcmp(zField,"remarks")==0 ){
    int len1, len2;
    len1 = strlen(zOld);
    len2 = strlen(zNew);
    if( len1==0 ){
      @ 增加 <i>%h(zField)</i>:<blockquote>
      output_formatted(&zNew[len1], zPage);
      @ </blockquote>
    }else if( len2>len1+5 && strncmp(zOld,zNew,len1)==0 ){
      @ 追加到 <i>%h(zField)</i>:<blockquote>
      output_formatted(&zNew[len1], zPage);
      @ </blockquote>
    }else{
      @ 修改 <i>%h(zField)</i>.
      diff_strings(1,zOld,zNew);
    }
  }else if( (!g.okWrite || g.isAnon) && strcmp(zField,"contact")==0 ){
    /* Do not show contact information to unprivileged users */
    @ 修改 <i>%h(zField)</i>
  }else if( strncmp(zField,"extra",5)==0 ){
    char zLabel[30];
    const char *zAlias;
    bprintf(zLabel,sizeof(zLabel),"%h_name", zField);
    zAlias = db_config(zLabel, zField);
    @ 修改 <i>%h(zAlias)</i> 由 "%h(zOld)" 为 "%h(zNew)"
  }else{
    @ 修改 <i>%h(zField)</i> 由 "%h(zOld)" 为 "%h(zNew)"
  }

  @ 由 %h(zUser) 于 %h(zDate)

  if( isLast && ok_to_undo_change(date, zUser) ){
    @ [<a href="tktundo?tn=%d(tn)&amp;u=%t(zUser)&amp;t=%d(date)">撤消
    @ 该修改</a>]</p>
  }

  @ </li>
}

/*
** Output a checkin record.
*/
static void ticket_checkin(
  time_t date,          /* date/time of the change */
  int cn,               /* change number */
  const char *zBranch,  /* branch of the change, may be NULL */
  const char *zUser,    /* user name that made the change */
  const char *zMessage  /* log message for the change */
){
  struct tm *pTm;
  char *z;
  char zDate[100];

  @ <li> 提交 

  output_chng(cn);
  if( zBranch && zBranch[0] ){
    @ on branch %h(zBranch):
  } else {
    cgi_printf(": "); /* want the : right up against the [cn] */
  }

  z = strdup(zMessage);
  if( output_trim_message(z, MN_CKIN_MSG, MX_CKIN_MSG) ){
    output_formatted(z, 0);
    @ &nbsp;[...]
  }else{
    output_formatted(z, 0);
  }

  pTm = localtime(&date);
  strftime(zDate, sizeof(zDate), "%Y-%b-%d %H:%M", pTm);
  @ (由 %h(zUser) 于 %h(zDate))
  @ </li>
}

/*
** Output an attachment record.
*/
static void ticket_attach(
  time_t date,          /* date/time of the attachment */
  int attachn,          /* attachment number */
  size_t size,          /* size, in bytes, of the attachment */
  const char *zUser,    /* username that created it */
  const char *zDescription,    /* description of the attachment */
  const char *zFilename /* name of attachment file */
){
  char zDate[100];
  struct tm *pTm;
  pTm = localtime(&date);
  strftime(zDate, sizeof(zDate), "%Y-%b-%d %H:%M:%S", pTm);
  @ <li> 附件 
  @ <a href="attach_get/%d(attachn)/%T(zFilename)">%h(zFilename)</a>
  @ %d(size) 字节，由 %h(zUser) 于 %h(zDate)增加。
  if( zDescription && zDescription[0] ){
    @ <br>
    output_formatted(zDescription,NULL);
    @ <br>
  }
  if( ok_to_delete_attachment(date, zUser) ){
    @ [<a href="attach_del?atn=%d(attachn)">删除</a>]
  }
  @ </li>
}

/*
** Output an inspection note.
*/
static void ticket_inspect(
  time_t date,              /* date/time of the inspection */
  int cn,                   /* change that was inspected */
  const char *zInspector,   /* username that did the inspection */
  const char *zResult       /* string describing the result */
){
  char zDate[100];
  struct tm *pTm;
  pTm = localtime(&date);
  strftime(zDate, sizeof(zDate), "%Y-%b-%d %H:%M:%S", pTm);
  @ <li> 检查报告 "%h(zResult)" 于 
  output_chng(cn);
  @ &nbsp;由 %h(zInspector) 于 %h(zDate)
  @ </li>
}

/*
** Output a derived ticket creation
*/
static void ticket_derived(
  time_t date,        /* date/time derived ticket was created */
  int tn,             /* number of derived ticket */
  const char* zOwner, /* creator of derived ticket */
  const char *zTitle  /* (currently unused) title of derived ticket */
){
  char zDate[100];
  struct tm *pTm;
  pTm = localtime(&date);
  strftime(zDate, sizeof(zDate), "%Y-%b-%d %H:%M:%S", pTm);
  @ <li> 衍生自
  output_ticket(tn,0);
  @ &nbsp;由 %h(zOwner) 于 %h(zDate)
  @ </li>
}

/*
** WEBPAGE: /tkthistory
**
** A webpage for viewing the history of a ticket. The history is a
** chronological mix of ticket actions, checkins, attachments, etc.
*/
void ticket_history(void){
  int tn = 0, rn = 0;
  int lasttn = 0;
  char **az;
  int i;
  char zPage[30];
  const char *zTn;
  time_t orig;
  char zDate[200];
  struct tm *pTm;

  login_check_credentials();
  if( !g.okRead ){ login_needed(); return; }
  throttle(1,0);
  history_update(0);
  zTn = PD("tn","");
  sscanf(zTn, "%d,%d", &tn, &rn);
  if( tn<=0 ){ cgi_redirect("index"); return; }

  bprintf(zPage,sizeof(zPage),"%d",tn);
  common_standard_menu("tktview", "search?t=1");

  if( rn>0 ){
    common_add_action_item(mprintf("tktview?tn=%d,%d",tn,rn), "查看");
  }else{
    common_add_action_item(mprintf("tktview?tn=%d",tn), "查看");
  }

  common_add_help_item("CvstracTicket");

  if( g.okWrite ){
    if( rn>0 ){
      common_add_action_item(mprintf("tktedit?tn=%d,%d",tn,rn), "编辑");
    }else{
      common_add_action_item(mprintf("tktedit?tn=%d",tn), "编辑");
    }
    if( attachment_max()>0 ){
      common_add_action_item(mprintf("attach_add?tn=%d",tn), "附件");
    }
  }
  add_tkt_tools(0,tn);

  /* Get the record from the database.
  */
  db_add_functions();
  az = db_query("SELECT title,origtime,owner FROM ticket WHERE tn=%d", tn);
  if( az == NULL || az[0]==0 ){
    cgi_redirect("index");
    return;
  }

  orig = atoi(az[1]);
  pTm = localtime(&orig);
  strftime(zDate, sizeof(zDate), "%Y-%b-%d %H:%M:%S", pTm);

  common_header("任务单 #%d 历史", tn);
  @ <h2>任务单 %d(tn) 历史: %h(az[0])</h2>
  @ <ol>
  @ <li>由 %h(zDate) 创建于 %h(az[2])</li>

  /* Grab various types of ticket activities from the db.
  ** All must be sorted by ascending time and the first field of each
  ** record should be epoch time. Second field is the record type.
  */
  az = db_query(
    /* Ticket changes
    */
    "SELECT chngtime AS 'time', 1 AS 'type', "
      "user, fieldid, oldval, newval, NULL "
    "FROM tktchng WHERE tn=%d "
    "UNION ALL "

    /* Checkins
    */
    "SELECT chng.date AS 'time', 2 AS 'type', "
       " chng.cn, chng.branch, chng.user, chng.message, chng.milestone "
    "FROM xref, chng WHERE xref.tn=%d AND xref.cn=chng.cn "
    "UNION ALL "

    /* attachments
    */
    "SELECT date AS 'time', 3 AS 'type', atn, size, user, description, fname "
    "FROM attachment WHERE tn=%d "
    "UNION ALL "

    /* inspection reports
    */
    "SELECT inspect.inspecttime AS 'time', 4 AS 'type', "
      "inspect.cn, inspect.inspector, inspect.result, NULL, NULL "
    "FROM xref, inspect "
    "WHERE xref.cn=inspect.cn AND xref.tn=%d "
    "UNION ALL "

    /* derived tickets. This is just the derived ticket creation. Could
    ** also report derived ticket changes, but we'd probably have to
    ** use some kind of tree representation.
    */
    "SELECT origtime AS 'time', 5 AS 'type', tn, owner, title, NULL, NULL "
    "FROM ticket WHERE derivedfrom=%d "

    "ORDER BY 1, 2",
    tn, tn, tn, tn, tn);

  /* find the last ticket change in the list. This is necessary to allow
  ** someone to undo the last change.
  */
  for(i=0; az[i]; i+=7){
    int type = atoi(az[i+1]);
    if( type==1 ) lasttn = i;
  }

  for(i=0; az[i]; i+=7) {
    time_t date = atoi(az[i]);
    int type = atoi(az[i+1]);
    switch( type ){
      case 1: { /* ticket change */
        ticket_change(date, tn, az[i+2],
          az[i+3], az[i+4], az[i+5], lasttn==i);
        break;
      }
      case 2: { /* checkin */
        ticket_checkin(date, atoi(az[i+2]), az[i+3], az[i+4], az[i+5]);
        break;
      }
      case 3: { /* attachment */
        ticket_attach(date, atoi(az[i+2]), atoi(az[i+3]),
          az[i+4], az[i+5], az[i+6]);
        break;
      }
      case 4: { /* inspection report */
        ticket_inspect(date, atoi(az[i+2]), az[i+3], az[i+4]);
        break;
      }
      case 5: { /* derived ticket creation */
        ticket_derived(date, atoi(az[i+2]), az[i+3], az[i+4]);
        break;
      }
      default:
        /* Can't happen */
        /* assert( type >= 1 && type <= 5 ); */
        break;
    }
  }
  @ </ol>
  common_footer();
}
