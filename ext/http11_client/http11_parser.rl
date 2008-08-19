/**
 * Copyright (c) 2005 Zed A. Shaw
 * You can redistribute it and/or modify it under the same terms as Ruby.
 */

#include "http11_parser.h"
#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#define LEN(AT, FPC) (FPC - buffer - parser->AT)
#define MARK(M,FPC) (parser->M = (FPC) - buffer)
#define PTR_TO(F) (buffer + parser->F)
#define L(M) fprintf(stderr, "" # M "\n");


/** machine **/
%%{
  machine httpclient_parser;

  action mark {MARK(mark, fpc); }

  action start_field { MARK(field_start, fpc); }

  action write_field { 
    parser->field_len = LEN(field_start, fpc);
  }

  action start_value { MARK(mark, fpc); }

  action write_value { 
    parser->http_field(parser->data, PTR_TO(field_start), parser->field_len, PTR_TO(mark), LEN(mark, fpc));
  }

  action reason_phrase { 
    parser->reason_phrase(parser->data, PTR_TO(mark), LEN(mark, fpc));
  }

  action status_code { 
    parser->status_code(parser->data, PTR_TO(mark), LEN(mark, fpc));
  }

  action http_version {	
    parser->http_version(parser->data, PTR_TO(mark), LEN(mark, fpc));
  }

  action chunk_size {
    parser->chunk_size(parser->data, PTR_TO(mark), LEN(mark, fpc));
  }

  action last_chunk {
    parser->last_chunk(parser->data, NULL, 0);
  }

  action done { 
    parser->body_start = fpc - buffer + 1; 
    if(parser->header_done != NULL)
      parser->header_done(parser->data, fpc + 1, pe - fpc - 1);
    fbreak;
  }

# line endings
  CRLF = "\r\n";

# character types
  CTL = (cntrl | 127);
  tspecials = ("(" | ")" | "<" | ">" | "@" | "," | ";" | ":" | "\\" | "\"" | "/" | "[" | "]" | "?" | "=" | "{" | "}" | " " | "\t");

# elements
  token = (ascii -- (CTL | tspecials));

  Reason_Phrase = (any -- CRLF)* >mark %reason_phrase;
  Status_Code = digit{3} >mark %status_code;
  http_number = (digit+ "." digit+) ;
  HTTP_Version = ("HTTP/" http_number) >mark %http_version ;
  Status_Line = HTTP_Version " " Status_Code " "? Reason_Phrase :> CRLF;

  field_name = token+ >start_field %write_field;
  field_value = any* >start_value %write_value;
  message_header = field_name ":" " "* field_value :> CRLF;

  Response = 	Status_Line (message_header)* (CRLF @done);

  chunk_ext_val = token+;
  chunk_ext_name = token+;
  chunk_extension = (";" chunk_ext_name >start_field %write_field %start_value ("=" chunk_ext_val >start_value)? %write_value )*;
  last_chunk = "0"? chunk_extension :> (CRLF @last_chunk @done);
  chunk_size = xdigit+;
  chunk = chunk_size >mark %chunk_size chunk_extension space* :> (CRLF @done);
  Chunked_Header = (chunk | last_chunk);

  main := Response | Chunked_Header;
}%%

/** Data **/
%% write data;

int httpclient_parser_init(httpclient_parser *parser)  {
  int cs = 0;
  %% write init;
  parser->cs = cs;
  parser->body_start = 0;
  parser->content_len = 0;
  parser->mark = 0;
  parser->nread = 0;
  parser->field_len = 0;
  parser->field_start = 0;    

  return(1);
}


/** exec **/
size_t httpclient_parser_execute(httpclient_parser *parser, const char *buffer, size_t len, size_t off)  {
  const char *p, *pe;
  int cs = parser->cs;

  assert(off <= len && "offset past end of buffer");

  p = buffer+off;
  pe = buffer+len;

  assert(*pe == '\0' && "pointer does not end on NUL");
  assert(pe - p == len - off && "pointers aren't same distance");


  %% write exec;

  parser->cs = cs;
  parser->nread += p - (buffer + off);

  assert(p <= pe && "buffer overflow after parsing execute");
  assert(parser->nread <= len && "nread longer than length");
  assert(parser->body_start <= len && "body starts after buffer end");
  assert(parser->mark < len && "mark is after buffer end");
  assert(parser->field_len <= len && "field has length longer than whole buffer");
  assert(parser->field_start < len && "field starts after buffer end");

  if(parser->body_start) {
    /* final \r\n combo encountered so stop right here */
    %%write eof;
    parser->nread++;
  }

  return(parser->nread);
}

int httpclient_parser_finish(httpclient_parser *parser)
{
  int cs = parser->cs;

  %%write eof;

  parser->cs = cs;

  if (httpclient_parser_has_error(parser) ) {
    return -1;
  } else if (httpclient_parser_is_finished(parser) ) {
    return 1;
  } else {
    return 0;
  }
}

int httpclient_parser_has_error(httpclient_parser *parser) {
  return parser->cs == httpclient_parser_error;
}

int httpclient_parser_is_finished(httpclient_parser *parser) {
  return parser->cs == httpclient_parser_first_final;
}
