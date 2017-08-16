%%% ******************************************************************************
%%%  Copyright (c) 2009 Vlad Dumitrescu and others.
%%%  All rights reserved. This program and the accompanying materials
%%%  are made available under the terms of the Eclipse Public License v1.0
%%%  which accompanies this distribution, and is available at
%%%  http://www.eclipse.org/legal/epl-v10.html
%%%
%%%  Contributors:
%%%      Vlad Dumitrescu
%%% ******************************************************************************/
-module(sourcer_module).

-export([
         start/1,
         contentChange/4
        ]).

-include("include/dbglog.hrl").

%% For now we have a simple content model: a string.

-record(state, {name, content=""}).

start(Name) ->
    spawn(fun() ->
                  erlang:process_flag(save_calls, 50),
                  loop(#state{name=Name})
          end).

contentChange(Pid, Offset, Length, Text) ->
    Pid ! {change, Offset, Length, Text}.


loop(State) ->
    Name = State#state.name,
    receive
        stop ->
            ok;
        {get_string_content, From} ->
            From ! {module_content, State#state.content},
            loop(State);
        {get_binary_content, From} ->
            From ! {module_content, list_to_binary(State#state.content)},
            loop(State);
        {change, Offset, Length, Text}=_Msg ->
            % erlide_log:logp("Module ~s:: ~p", [Name, _Msg]),
            Content1 = replace_text(State#state.content, Offset, Length, Text),
            loop(State#state{content=Content1});
        Msg ->
            %erlide_log:logp("Unknown message in module ~s: ~p", [Name, Msg]),
            loop(State)
    end.

replace_text(Initial, Offset, Length, Text) ->
    {A, B} = lists:split(Offset, Initial),
    {_, C} = lists:split(Length, B),
    A++Text++C.
