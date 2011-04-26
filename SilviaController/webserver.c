
/******************************************************************************

  Filename:		webserver.h
  Description:	Webserver app for the WiShield 1.0

 ******************************************************************************

  TCP/IP stack and driver for the WiShield 1.0 wireless devices

  Copyright(c) 2009 Async Labs Inc. All rights reserved.

  This program is free software; you can redistribute it and/or modify it
  under the terms of version 2 of the GNU General Public License as
  published by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
  more details.

  You should have received a copy of the GNU General Public License along with
  this program; if not, write to the Free Software Foundation, Inc., 59
  Temple Place - Suite 330, Boston, MA  02111-1307, USA.

  Contact Information:
  <asynclabs@asynclabs.com>

   Author               Date        Comment
  ---------------------------------------------------------------
   AsyncLabs			05/29/2009	Initial version

 *****************************************************************************/


#include "uip.h"
#include <string.h>
#include "webserver.h"
#include "config.h"

extern float temp;
extern float ambient;
extern float setpoint;
extern unsigned long int lastStart;

static int handle_connection(struct webserver_state *s);

void webserver_init(void)
{
	uip_listen(HTONS(80));
}

void webserver_appcall(void)
{
	struct webserver_state *s = &(uip_conn->appstate);

	if(uip_connected()) {
		PSOCK_INIT(&s->p, s->inputbuf, sizeof(s->inputbuf));
	}

	handle_connection(s);
}

#define ISO_nl      0x0a
#define ISO_space   0x20
#define ISO_slash   0x2f

//const char http_get[5] = {0x47, 0x45, 0x54, 0x20, };	/* "GET " */

static int handle_connection(struct webserver_state *s)
{
	PSOCK_BEGIN(&s->p);

	// the incoming GET request will have the following format:
	// GET / HTTP/1.1 ....
	// we have to parse this string to determine the resource being requested
	// if the requested resource is not the root webpage ('/') then,
	// GET /<resource name> HTTP/1.1 ....
	// we should parse the specific resource and react appropriately

	// read incoming data until we read a space character
	PSOCK_READTO(&s->p, ISO_space);

	// parse the data to determine if it was a GET request
	if(strncmp(s->inputbuf, "GET ", 4) != 0) {
		PSOCK_CLOSE_EXIT(&s->p);
	}

	// continue reading until the next space character
	PSOCK_READTO(&s->p, ISO_space);
        
        //s->inputbuf now contains the requested URL
	if(s->inputbuf[0] != ISO_slash) {
		// request for unknown webpage, close and exit
		PSOCK_CLOSE_EXIT(&s->p);
	}
         
	if(s->inputbuf[1] != ISO_space) //action requested! 
        {
          if(strncmp(s->inputbuf, "/start", 6) == 0)
          {
            setpoint = 100.0;
            lastStart = millis();
          }
          if(strncmp(s->inputbuf, "/up", 3) == 0)
          {
            setpoint += 1.0;
          }
          if(strncmp(s->inputbuf, "/down", 5) == 0)
          {
            setpoint += -1.0;
          }
          if(strncmp(s->inputbuf, "/stop", 5) == 0)
          {
            setpoint = 0.0;
          }
	}

	PSOCK_SEND_STR(&s->p, "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n");
	PSOCK_SEND_STR(&s->p, "{\"temp\":");
	PSOCK_SEND_STR(&s->p, dtostrf(temp, 5,2));
	PSOCK_SEND_STR(&s->p, ",\"target\":");
	PSOCK_SEND_STR(&s->p, dtostrf(setpoint, 5,2));
	PSOCK_SEND_STR(&s->p, "}");
	PSOCK_CLOSE(&s->p);
	PSOCK_END(&s->p);
}
