MENU = {

  :main => [['H', "H - Help",       {:go=>:help}],
            ['N', "N - Network",    {:cb=>:display_network}],
            ['S', "S - Save map",    {:cb=>:save_map}],
            ['Q', "Q - Quit menu",  {:go=>:quit}]],
              
  :help => [['', "e: Editor", {}],
            ['', "", {}],
            ['Q', "Q - Back", {:go=>:main}]]
  
}

