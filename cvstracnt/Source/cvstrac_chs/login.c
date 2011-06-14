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
** �������ķ���: �ܾ��� (zjy@cnpack.org) 2003-11-09
**
*******************************************************************************
**
** This file contains code for generating the login and logout screens.
*/
#define _XOPEN_SOURCE
#include <unistd.h>
#include "config.h"
#include "login.h"
#include <time.h>
#ifdef CVSTRAC_WINDOWS
/* Used by "use Windows password" feature */
#include <windows.h>
typedef BOOL (CALLBACK FNLOGONUSERA)(LPTSTR, LPTSTR, LPTSTR, DWORD, DWORD, PHANDLE);
#endif

/*
** Return the name of the login cookie
*/
static char *login_cookie_name(void){
  return mprintf("%s_login", g.zName);
}

/*
** WEBPAGE: /login
** WEBPAGE: /logout
**
** Generate the login page
*/
void login_page(void){
  const char *zUsername, *zPasswd, *zGoto;
  const char *zNew1, *zNew2;
  char *zErrMsg = "";
  char *z;
#ifdef CVSTRAC_WINDOWS
  /* Loads _LogonUserA which is used by "use Windows password feature. */
  HMODULE hAdvapiModule = LoadLibraryA("Advapi32.dll");
  FNLOGONUSERA *_LogonUserA = hAdvapiModule ? (FNLOGONUSERA *)GetProcAddress(hAdvapiModule, "LogonUserA") : NULL;
  HANDLE hToken = NULL;
#endif

  login_check_credentials();
  zUsername = P("u");
  zPasswd = P("p");
  zGoto = P("g");
  if( P("out")!=0 ){
    const char *zCookieName = login_cookie_name();
    cgi_set_cookie(zCookieName, "", 0, time(NULL)-(60*60*24));
    db_execute("DELETE FROM cookie WHERE cookie='%q'", P(zCookieName));
    cgi_redirect(PD("nxp","index"));
    return;
  }
  if( !g.isAnon && zPasswd && (zNew1 = P("n1"))!=0 && (zNew2 = P("n2"))!=0 ){
    z = db_short_query("SELECT passwd FROM user WHERE id='%q'", g.zUser);
    if( z==0 || z[0]==0 || strcmp(crypt(zPasswd,z),z)!=0 ){
      sleep(1);
      zErrMsg = 
         @ <p class="error">
         @ ���ڳ����޸�����ʱ������һ����������룬
         @ ��������û�б��޸ġ�
         @ </p>
      ;
    }else if( strcmp(zNew1,zNew2)!=0 ){
      zErrMsg = 
         @ <p class="error">
         @ ����������������벻һ�£�
         @ ��������û�б��޸ġ�
         @ </p>
      ;
    }else{
      db_execute(
         "UPDATE user SET passwd='%q' WHERE id='%q'",
         crypt(zNew1,zPasswd), g.zUser
      );
      if( g.scm.pxUserWrite ) g.scm.pxUserWrite(0);
      cgi_redirect("index");
      return;
    }
  }
  if( zUsername!=0 && zPasswd!=0 && strcmp(zUsername,"anonymous")!=0 ){
    z = db_short_query("SELECT passwd FROM user WHERE id='%q'", zUsername);
    if(
#ifdef CVSTRAC_WINDOWS
        /* Windows domain login when password is set to "*" in the database */
        z==0 || z[0]==0 || ((z[0]!='*' || z[1]!=0) && strcmp(crypt(zPasswd,z),z)!=0) ||
        (z[0]=='*' && z[1]==0 && !_LogonUserA((LPTSTR)zUsername, ".", (LPTSTR)zPasswd, LOGON32_LOGON_NETWORK, LOGON32_PROVIDER_DEFAULT, &hToken))
#else
        z==0 || z[0]==0 || strcmp(crypt(zPasswd,z),z)!=0
#endif
    ){
      sleep(1);
      zErrMsg = 
         @ <p class="error">
         @ ��������һ����Ч���û��������롣
         @ </p>
      ;
    }else{
      time_t now;
      unsigned char *zDigest;
      const char *zAddr;
      const char *zAgent;
      unsigned char zHash[200];
      unsigned char zRawDigest[16];
      MD5Context ctx;

      time(&now);
      bprintf((char *)zHash,sizeof(zHash),"%d%d%.19s", getpid(), (int)now, zPasswd);
      MD5Init(&ctx);
      MD5Update(&ctx, zHash, strlen((char *)zHash));
      MD5Final(zRawDigest, &ctx);
      zDigest = encode64(zRawDigest, 16);
      zAddr = getenv("REMOTE_ADDR");
      if( zAddr==0 ) zAddr = "0.0.0.0";
      zAgent = getenv("HTTP_USER_AGENT");
      if( zAgent==0 ) zAgent = "Unknown";
      db_execute(
        "BEGIN;"
        "DELETE FROM cookie WHERE expires<=%d;"
        "INSERT INTO cookie(cookie,user,expires,ipaddr,agent)"
        "  VALUES('%q','%q',%d,'%q','%q');"
        "COMMIT;",
        now, zDigest, zUsername, now+3600*24, zAddr, zAgent
      );
      cgi_set_cookie(login_cookie_name(), (char *)zDigest, 0, 0);
      cgi_redirect(PD("nxp","index"));
      return;
    }
    free(z);
  }
#ifdef CVSTRAC_WINDOWS
  /* Closes handle to Windows login token. */
  if(hToken) CloseHandle(hToken);
#endif
  common_standard_menu("login", 0);
  common_add_help_item("CvstracLogin");
  common_header("��¼/ע��");
  @ %s(zErrMsg)
  @ <form action="login" method="POST">
  if( P("nxp") ){
    @ <input type="hidden" name="nxp" value="%h(P("nxp"))">
  }
  @ <table align="left" style="margin: 0 10px;">
  @ <tr>
  @   <td align="right">�û���:</td>
  @   <td><input type="text" name="u" value="" size=30></td>
  @ </tr>
  @ <tr>
  @  <td align="right">����:</td>
  @   <td><input type="password" name="p" value="" size=30></td>
  @ </tr>
  @ <tr>
  @   <td></td>
  @   <td><input type="submit" name="in" value="��¼"></td>
  @ </tr>
  @ </table>
  if( g.isAnon ){
    @ <p>Ҫ��¼��
  }else{
    @ <p>����ǰ���û��� <b>%h(g.zUser)</b> ��¼��</p>
    @ <p>�������ʹ����һ���û�����¼��
  }
  @ ��������������û��������벢���
  @ "��¼" ��ť�������û��������洢��������� Cookie �С�
  @ ��ȷ���������������ʹ�� Cookie �Խ��е�¼
  @ ������</p>
  if( db_exists("SELECT id FROM user WHERE id='anonymous'") ){
    @ <p>�÷�����������Ϊ����δ��¼�û�
    @ ʹ�á�</p>
  }
  if( !g.isAnon ){
    @ <br clear="all"><hr>
    @ <p>���Ҫע��ϵͳ����ɾ�� Cookie �еĵ�¼��Ϣ����
    @  ��������İ�ť:<br>
    @ <input type="submit" name="out" value="ע��"></p>
  }
  @ </form>
  if( !g.isAnon && g.okPassword ){
    @ <br clear="all"><hr>
    @ <p>Ҫ�޸��������룬��������ԭ�������룬�����������µ����룬
    @ Ȼ��������� "�޸�����"
    @ ��ť��</p>
    @ <form action="login" method="POST">
    @ <table>
    @ <tr><td align="right">ԭ����:</td>
    @ <td><input type="password" name="p" size=30></td></tr>
    @ <tr><td align="right">������:</td>
    @ <td><input type="password" name="n1" size=30></td></tr>
    @ <tr><td align="right">�ظ�����:</td>
    @ <td><input type="password" name="n2" size=30></td></tr>
    @ <tr><td></td>
    @ <td><input type="submit" value="�޸�����"></td></tr>
    @ </table>
    @ </form>
  }
  common_footer();
}

/*
** This routine examines the login cookie to see if it exists and
** contains a valid password hash.  If the login cookie checks out,
** it then sets g.zUser to the name of the user and set g.isAnon to 0.
**
** Permission variable are set as appropriate:
**
**   g.okRead        User can read bug reports and change histories
**   g.okDelete      User can delete wiki, tickets, and attachments
**   g.okCheckout    User can read from the repository
**   g.okWrite       User can change bug reports
**   g.okCheckin     User can checking changes to the repository
**   g.okAdmin       User can add or delete other user and create new reports
**   g.okSetup       User can change CVSTrac options
**   g.okPassword    User can change his password
**   g.okQuery       User can enter or edit SQL report formats.
**
**   g.okRdWiki      User can read wiki pages
**   g.okWiki        User and create or modify wiki pages
**
*/
void login_check_credentials(void){
  const char *zCookie;
  time_t now;
  char **azResult, *z;
  int i;
  const char *zUser;
  const char *zPswd;
  const char *zAddr;     /* The IP address of the browser making this request */
  const char *zAgent;    /* The type of browser */

  g.zUser = g.zHumanName = "anonymous";
  g.okPassword = 0;
  g.okRead = 0;
  g.okNewTkt = 0;
  g.okWrite = 0;
  g.okAdmin = 0;
  g.okSetup = 0;
  g.okCheckout = 0;
  g.okCheckin = 0;
  g.okRdWiki = 0;
  g.okWiki = 0;
  g.okDelete = 0;
  g.okQuery = 0;
  g.isAnon = 1;
  time(&now);

  /*
  ** Check to see if there is an anonymous user.  Everybody gets at
  ** least the permissions that anonymous enjoys.
  */
  z = db_short_query("SELECT capabilities FROM user WHERE id='anonymous'");
  if( z && z[0] ){
    for(i=0; z[i]; i++){
      switch( z[i] ){
        case 'd':   g.okDelete = 1;                  break;
        case 'i':   g.okCheckin = g.okCheckout = 1;  break;
        case 'j':   g.okRdWiki = 1;                  break;
        case 'k':   g.okWiki = g.okRdWiki = 1;       break;
        case 'n':   g.okNewTkt = 1;                  break;
        case 'o':   g.okCheckout = 1;                break;
        case 'p':   g.okPassword = 1;                break;
        case 'q':   g.okQuery = 1;                   break;
        case 'r':   g.okRead = 1;                    break;
        case 'w':   g.okWrite = g.okRead = 1;        break;
      }
    }
  }

  g.okTicketLink = atoi(db_config("anon_ticket_linkinfo","0"));
  g.okCheckinLink = atoi(db_config("anon_checkin_linkinfo","0"));
  g.noFollow = atoi(db_config("nofollow_link","0"));

  /*
  ** Next check to see if the user specified by "U" and "P" query
  ** parameters or by the login cookie exists
  */
  if( (zUser = P("U"))!=0 && (zPswd = P("P"))!=0 ){
    z = db_short_query("SELECT passwd FROM user WHERE id='%q'", zUser);
    if( z==0 || z[0]==0 || strcmp(crypt(zPswd,z),z)!=0 ){
      return;
    }
  }else if( (zCookie = P(login_cookie_name()))!=0 && zCookie[0]!=0 ){
    zAddr = getenv("REMOTE_ADDR");
    if( zAddr==0 ) zAddr = "0.0.0.0";
    zAgent = getenv("HTTP_USER_AGENT");
    if( zAgent==0 ) zAgent = "Unknown";
    zUser = db_short_query(
      "SELECT user FROM cookie "
      "WHERE cookie='%q' "
      "  AND ipaddr='%q' "
      "  AND agent='%q' "
      "  AND expires>%d",
      zCookie, zAddr, zAgent, now);
    if( zUser==0 ){
      return;
    }
  }else{
    return;
  }

  /* If we reach here, it means that the user named "zUser" checks out.
  ** Set up appropriate permissions.
  */
  azResult = db_query(
    "SELECT name, capabilities FROM user "
    "WHERE id='%q'", zUser
  );
  if( azResult[0]==0 ){
    return;  /* Should never happen... */
  }
  g.isAnon = 0;
  g.zHumanName = azResult[0];
  g.zUser = zUser;
  cgi_logfile(0, g.zUser);
  for(i=0; azResult[1][i]; i++){
    switch( azResult[1][i] ){
      case 's':   g.okSetup = g.okDelete = 1;
      case 'a':   g.okAdmin = g.okRead = g.okWrite = g.okQuery =
#ifdef CVSTRAC_WINDOWS
                              /* On Windows we may have admins that have
                              ** passwords synchronized to domain account,
                              ** so we don't want them to change the passwords.
                              */
                              g.okNewTkt = 1;
#else
                              g.okNewTkt = g.okPassword = 1;
#endif
      case 'i':   g.okCheckin = g.okCheckout = 1;  break;
      case 'd':   g.okDelete = 1;                  break;
      case 'j':   g.okRdWiki = 1;                  break;
      case 'k':   g.okWiki = g.okRdWiki = 1;       break;
      case 'n':   g.okNewTkt = 1;                  break;
      case 'o':   g.okCheckout = 1;                break;
      case 'p':   g.okPassword = 1;                break;
      case 'q':   g.okQuery = 1;                   break;
      case 'r':   g.okRead = 1;                    break;
      case 'w':   g.okWrite = g.okRead = 1;        break;
    }
  }
  g.okTicketLink = atoi(db_config("ticket_linkinfo","1"));
  g.okCheckinLink = atoi(db_config("checkin_linkinfo","0"));
}

/*
** Call this routine when the credential check fails.  It causes
** a redirect to the "login" page.
*/
void login_needed(void){
  const char *zUrl = getenv("REQUEST_URI");
  if( zUrl==0 ) zUrl = "index";
  cgi_redirect(mprintf("login?nxp=%T", zUrl));
}