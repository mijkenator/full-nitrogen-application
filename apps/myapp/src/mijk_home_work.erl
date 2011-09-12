%% -*- mode: nitrogen -*-
-module (mijk_home_work).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").

-define(FLICKRAPIKEY, "960b8fa01a47f73712064cf3b932bdcd").
-define(FLICKRAPISECRET, "1fb571a910ff1d32").

main() -> #template { file="apps/web/priv/templates/bare.html" }.


title() -> "Hi Kunthar".

body() ->
    Cities = get_cities(),
    wf:comet(fun() -> counter1(Cities) end),
    wf:comet(fun() -> counter2() end),
    wf:comet(fun() -> counter3() end),
    #container_12 { body=[
        #grid_8 { alpha=true, prefix=2, suffix=2, omega=true, body=inner_body() }
    ]}.

inner_body() -> 
    [
        #h3 { text="Cities" },
        #p{},
	#panel { id=placeholder1 },
	#h3 { text="Weather in Princeton, NJ" },
	#p{},
	#panel { id=placeholder2 },
	#h3 { text="Random photo from flickr" },
	#p{},
	#panel { id=placeholder3 }
    ].

counter1(Cities) ->
    wf:update(placeholder1, mochijson2:encode(Cities)),
    wf:flush(),
    timer:sleep(10000),
    counter1(shift_cities(Cities)).

counter2() ->
    wf:update(placeholder2, get_weather()),
    wf:flush().

counter3() ->
    wf:update(placeholder3, [#image { image=get_random_flickr() }]),
    wf:flush(),
    timer:sleep(10000),
    counter3().

get_weather() ->
    case httpc:request("http://free.worldweatheronline.com/feed/weather.ashx?q=08550&format=json&key=70590d4d2f000742111109") of
	{ok,{{_,200,"OK"},_,JSONString}} ->
	    {struct,[{<<"data">>,{struct,[{<<"current_condition">>,[{struct,WeatherPList}]},_,_]}}]} = mochijson2:decode(JSONString),
	    "Temperature:" ++ binary_to_list(proplists:get_value(<<"temp_C">>, WeatherPList)) ++ ", "
	    "Humidity:" ++ binary_to_list(proplists:get_value(<<"humidity">>, WeatherPList))
	;_ -> "weather data unavailable"
    end.

get_random_flickr() ->
    SearchPattern = ["dog", "cat", "funny", "mole", "snake", "fish", "puppy", "dwight", "shrute"],
    FlickrURL = "http://api.flickr.com/services/rest/?method=flickr.photos.search&text=" ++
    lists:nth(random:uniform(length(SearchPattern)), SearchPattern) ++ "&api_key="
    ?FLICKRAPIKEY ++ "&per_page=" ++ "10" ++  "&format=json",
    case httpc:request(FlickrURL) of
	{ok,{{_,200,"OK"},_,JSONString}} ->
	    {struct,[{<<"photos">>,{struct, S}},_]} = mochijson2:decode(string:substr(JSONString,15,string:len(JSONString)-15)),
	    case proplists:get_value(<<"photo">>, S) of
		S1 when is_list(S1), length(S1) > 0 ->
		    Url = make_flickr_image_url(lists:nth(random:uniform(length(S1)),S1)),
		    ?PRINT(Url),
		    Url
		;_->[]
	    end
	;_-> []
    end.

make_flickr_image_url({struct, ImagePropList}) ->
    "http://farm" ++ integer_to_list(proplists:get_value(<<"farm">>, ImagePropList)) ++ ".static.flickr.com/" ++
    binary_to_list(proplists:get_value(<<"server">>, ImagePropList)) ++ "/" ++
    binary_to_list(proplists:get_value(<<"id">>, ImagePropList)) ++ "_" ++
    binary_to_list(proplists:get_value(<<"secret">>, ImagePropList)) ++ ".jpg".

get_cities() ->
    case httpc:request("http://api.geonames.org/citiesJSON?north=41.1&south=-9.9&east=-22.4&west=55.2&lang=de&username=demo&maxRows=10") of
	{ok,{{_,200,"OK"},_,JSONString}} ->
	    make_cities_tuple(mochijson2:decode(JSONString))
	;_-> []
    end.


make_cities_tuple({struct,[{<<"geonames">>, SList}]}) -> mct(SList, []);
make_cities_tuple(
    {struct,[{<<"status">>,{struct,[{<<"message">>,
        <<"the hourly limit of 2000 credits demo has been exceeded. Please throttle your requests or use the commercial service.">>},_]}}]}
    ) -> 
    [{struct, ["error","can't get list of cities from api.geonames. Konwn error."]}];
make_cities_tuple(_) -> [{struct, ["error","can't get list of cities from api.geonames. Unknown error"]}].

mct([],A)     		-> A;
mct([{struct, H}|T], A) -> 
    mct(T,[{struct,[
	{<<"name">>, 		proplists:get_value(<<"name">>,        H)},
	{<<"country">>, 	proplists:get_value(<<"countrycode">>, H)},
	{<<"population">>, 	proplists:get_value(<<"population">>,  H)}
    ]}] ++ A).

shift_cities([H|T]) ->
    [lists:last(T)] ++ lists:sublist(T, length(T)-1) ++ [H].

