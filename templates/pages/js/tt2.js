[%  # Template to generate main Javascript file.  It glues
    # together several smaller components from the library of
    # js/* templates, some of which use template variable to 
    # soft-code certain values (stylesheet names, etc).
   
    INCLUDE js/cookie   # get/set cookes, for stylesheets 
          + js/loader   # page onload handlers
          + js/style    # stylesheet switcher
          + js/switcher # open/close sections
%]
