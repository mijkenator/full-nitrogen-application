-module(web_common).
-include_lib ("nitrogen_core/include/wf.hrl").
-compile(export_all).

header(Selected) ->
    wf:wire(Selected, #add_class { class=selected }),
    #panel { class=menu, body=[
        #link { id=index, url='/', text="INDEX" },
        #link { id=page1, url='/page1', text="PAGE 1" }
	#link { id=page2, url='/page2', text="Kunthar click me!" }
    ]}.


footer() ->
    #panel { class=credits, body=[
        "
        Nitrogen is copyright &copy; 2008-2010 <a href='http://rklophaus.com'>Rusty Klophaus</a>. 
        <img src='/images/MiniSpaceman.png' style='vertical-align: middle;' />
        Released under the MIT License.
        "
    ]}.

assert_path( Str ) when is_list( Str ) ->
    assert_path( #template { 
       file=filename:join([code:priv_dir(web), 
			   "templates", 
			   Str
			  ])
});

assert_path( Elem=#template {} ) ->
    case wf:path_info() of
        [] -> Elem;
        _ -> web_404:main()
     end.
