require 'mkmf'

dir_config("rev_buffer")
have_library("c", "main")

create_makefile("rev_buffer")