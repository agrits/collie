defmodule Collie.ParserTest do
  use ExUnit.Case

  alias Collie.Parser

  @operations ~w(+ - * / == > < <= =< /= rem div or and not xor band bor bxor bnot)

  describe "parse_forms/1" do
    test "atom" do
      test_construct({:atom, :A, 1}, {:atom, 1, :A})
    end

    test "float" do
      test_construct({:float, 1.0, 1}, {:float, 1, 1.0})
    end

    test "integer" do
      test_construct({:float, 2, 1}, {:float, 1, 2})
    end

    test "string" do
      test_construct({:string, "a", 1}, {:string, 1, String.to_charlist("a")})
    end

    test "binary" do
      test_construct(
        {:binary, [{:string, "a", 1}], 1},
        {:bin, 1, [{:bin_element, 1, {:string, 1, 'a'}, :default, :default}]}
      )
    end

    test "binc" do
      test_construct(
        {:list, [{:symbol, "binc", 1}, {:binary, [{:string, "a", 1}], 1}], 1},
        {:bin, 1, [{:bin_element, 1, {:string, 1, 'a'}, :default, [:binary]}]}
      )

      test_construct(
        {:list, [{:symbol, "binc", 1}, {:string, "a", 1}], 1},
        {:bin, 1, [{:bin_element, 1, {:string, 1, 'a'}, :default, [:binary]}]}
      )
    end

    test "var" do
      test_construct({:var, :A, 1}, {:var, 1, :A_})
      test_construct({:var, :a, 1}, {:var, 1, :A})
      test_construct({:var, :_, 1}, {:var, 1, :_})
    end

    test "hashmap" do
      test_construct(
        {:hashmap, %{{:atom, :a, 0} => {:atom, :b, 0}}, 0},
        {:map, 0, [{:map_field_assoc, 0, {:atom, 0, :a}, {:atom, 0, :b}}]}
      )
    end

    test "vector" do
      test_construct({:vector, [{:atom, :a, 1}], 1}, {:tuple, 1, [{:atom, 1, :a}]})
    end

    test "list" do
      test_construct({:list, [{:atom, :a, 1}], 1}, {:cons, 1, {:atom, 1, :a}, {nil, 1}})
      test_construct({:list, [{:tail, {:atom, :a, 1}}], 1}, {:atom, 1, :a})
    end

    test "varcall" do
      test_construct(
        {:list, [{:varcall, :a, 1}, {:atom, :b, 1}], 1},
        {:call, 1, {:atom, 1, :A}, [{:atom, 1, :b}]}
      )
    end

    test "call" do
      test_construct(
        {:list, [{:symbol, "A", 1}, {:atom, :b, 1}], 1},
        {:call, 1, {:atom, 1, :A}, [{:atom, 1, :b}]}
      )
    end

    test "operation" do
      for op <- @operations do
        test_construct(
          {:list, [{:symbol, op, 1}, {:integer, 1, 1}, {:integer, 2, 1}], 1},
          {:op, 1, String.to_atom(op), {:integer, 1, 1}, {:integer, 1, 2}}
        )
      end
    end

    test "lambda" do
      test_construct(
        {:list,
         [{:symbol, "lambda", 1}, {:list, [{:atom, :a, 1}], 1}, {:list, [{:atom, :b, 1}], 1}], 1},
        {:fun, 1, {:clauses, [{:clause, 1, [{:atom, 1, :a}], [], [{:atom, 1, :b}]}]}}
      )
    end

    test "export" do
      test_construct(
        {:list,
         [
           {:symbol, "export", 1},
           {:list, [{:vector, [{:symbol, "A", 1}, {:integer, 0, 1}], 1}], 1}
         ], 1},
        {:attribute, 1, :export, [A: 0]}
      )
    end

    test "match" do
      test_construct(
        {:list, [{:symbol, "=", 1}, {:atom, :a, 1}, {:atom, :a, 1}], 1},
        {:match, 1, {:atom, 1, :a}, {:atom, 1, :a}}
      )
    end

    test "compile" do
      test_construct(
        {:list, [{:symbol, "compile", 1}, {:atom, :a, 1}], 1},
        {:attribute, 1, :compile, {:a}}
      )
    end

    test "module" do
      test_construct(
        {:list, [{:symbol, "module", 1}, {:symbol, "A", 1}], 1},
        {:attribute, 1, :module, :A}
      )
    end

    test "erlang_remote" do
      test_construct(
        {:list, [{:erlang_remote, "a", "b", 1}], 1},
        {:call, 1, {:remote, 1, {:atom, 1, :a}, {:atom, 1, :b}}, []}
      )
    end

    test "if" do
      test_construct(
        {:list, [{:symbol, "if", 1}, {:atom, nil, 1}, {:atom, :a, 1}], 1},
        {:if, 1, [{:clause, 1, [], [{:atom, 1, nil}], [{:atom, 1, :a}]}]}
      )
    end

    test "case" do
      test_construct(
        {:list,
         [{:symbol, "case", 1}, {:atom, nil, 1}, {:list, [{:atom, nil, 1}, {:atom, :a, 1}], 1}],
         1},
        {:case, 1, {:atom, 1, nil}, [{:clause, 1, [{:atom, 1, nil}], [], [{:atom, 1, :a}]}]}
      )
    end

    test "handler" do
      test_construct(
        {:list,
         [
           {:symbol, "handler", 1},
           {:symbol, "A", 1},
           {:hashmap, %{{:symbol, "GET", 1} => {:symbol, "a", 1}}, 1}
         ], 1},
        [
          {:attribute, 0, :module, :A},
          {:attribute, 2, :export, [init: 2]},
          {:function, 5, :init, 2,
           [
             {:clause, 6, [{:var, 6, :Req}, {:var, 6, :_state}], [],
              [
                {:call, 8, {:atom, 8, :handle_req},
                 [
                   {:call, 9, {:remote, 9, {:atom, 9, :maps}, {:atom, 9, :get}},
                    [{:atom, 9, :method}, {:var, 9, :Req}]},
                   {:var, 9, :Req}
                 ]}
              ]}
           ]},
          {:function, 11, :handle_req, 2,
           [
             {:clause, 13,
              [
                {:bin, 13, [{:bin_element, 13, {:string, 13, 'GET'}, :default, :default}]},
                {:var, 13, :Req}
              ], [], [{:call, 15, {:atom, 15, :a}, [{:var, 15, :Req}]}]},
             {:clause, 18, [{:var, 18, :_}, {:var, 18, :Req}], [],
              [
                {:call, 20, {:remote, 20, {:atom, 20, :cowboy_req}, {:atom, 20, :reply}},
                 [{:integer, 20, 404}, {:var, 20, :Req}]}
              ]}
           ]},
          {:function, 25, :reply_json, 3,
           [
             {:clause, 26, [{:var, 26, :Req}, {:var, 26, :Body}, {:var, 26, :Status}], [],
              [
                {:call, 28, {:remote, 28, {:atom, 28, :cowboy_req}, {:atom, 28, :reply}},
                 [
                   {:var, 28, :Status},
                   {:map, 28,
                    [
                      {:map_field_assoc, 28,
                       {:bin, 28,
                        [{:bin_element, 28, {:string, 28, 'content-type'}, :default, :default}]},
                       {:bin, 28,
                        [
                          {:bin_element, 28, {:string, 28, 'application/json'}, :default,
                           :default}
                        ]}}
                    ]},
                   {:call, 28, {:remote, 28, {:atom, 28, :jsone}, {:atom, 28, :encode}},
                    [{:var, 28, :Body}]},
                   {:var, 28, :Req}
                 ]}
              ]}
           ]},
          {:function, 30, :from_body, 2,
           [
             {:clause, 30, [{:var, 30, :Req}, {:var, 30, :Key}], [],
              [
                {:match, 32, {:tuple, 32, [{:atom, 32, :ok}, {:var, 32, :Body}, {:var, 32, :_}]},
                 {:call, 32,
                  {:remote, 32, {:atom, 32, :cowboy_req}, {:atom, 32, :read_urlencoded_body}},
                  [{:var, 32, :Req}]}},
                {:call, 33, {:remote, 33, {:atom, 33, :lists}, {:atom, 33, :keyfind}},
                 [{:var, 33, :Key}, {:integer, 33, 1}, {:var, 33, :Body}]}
              ]}
           ]},
          {:function, 36, :from_url, 2,
           [
             {:clause, 36, [{:var, 36, :Req}, {:var, 36, :Key}], [],
              [
                {:call, 38, {:remote, 38, {:atom, 38, :cowboy_req}, {:atom, 38, :binding}},
                 [{:var, 38, :Key}, {:var, 38, :Req}]}
              ]}
           ]}
        ]
      )

      test_construct(
        {:list,
         [
           {:symbol, "handler", 1},
           {:symbol, "A", 1},
           {:hashmap, %{{:symbol, "DEFAULT", 1} => {:symbol, "a", 1}}, 1}
         ], 1},
        [
          {:attribute, 0, :module, :A},
          {:attribute, 2, :export, [init: 2]},
          {:function, 5, :init, 2,
           [
             {:clause, 6, [{:var, 6, :Req}, {:var, 6, :_state}], [],
              [
                {:call, 8, {:atom, 8, :handle_req},
                 [
                   {:call, 9, {:remote, 9, {:atom, 9, :maps}, {:atom, 9, :get}},
                    [{:atom, 9, :method}, {:var, 9, :Req}]},
                   {:var, 9, :Req}
                 ]}
              ]}
           ]},
          {:function, 11, :handle_req, 2,
           [
             {:clause, 13,
              [
                {:bin, 13, [{:bin_element, 13, {:string, 13, 'DEFAULT'}, :default, :default}]},
                {:var, 13, :Req}
              ], [], [{:call, 15, {:atom, 15, :a}, [{:var, 15, :Req}]}]},
             {:clause, 18, [{:var, 18, :_}, {:var, 18, :Req}], [],
              [
                {:call, 20, {:remote, 20, {:atom, 20, :cowboy_req}, {:atom, 20, :reply}},
                 [{:integer, 20, 404}, {:var, 20, :Req}]}
              ]}
           ]},
          {:function, 25, :reply_json, 3,
           [
             {:clause, 26, [{:var, 26, :Req}, {:var, 26, :Body}, {:var, 26, :Status}], [],
              [
                {:call, 28, {:remote, 28, {:atom, 28, :cowboy_req}, {:atom, 28, :reply}},
                 [
                   {:var, 28, :Status},
                   {:map, 28,
                    [
                      {:map_field_assoc, 28,
                       {:bin, 28,
                        [{:bin_element, 28, {:string, 28, 'content-type'}, :default, :default}]},
                       {:bin, 28,
                        [
                          {:bin_element, 28, {:string, 28, 'application/json'}, :default,
                           :default}
                        ]}}
                    ]},
                   {:call, 28, {:remote, 28, {:atom, 28, :jsone}, {:atom, 28, :encode}},
                    [{:var, 28, :Body}]},
                   {:var, 28, :Req}
                 ]}
              ]}
           ]},
          {:function, 30, :from_body, 2,
           [
             {:clause, 30, [{:var, 30, :Req}, {:var, 30, :Key}], [],
              [
                {:match, 32, {:tuple, 32, [{:atom, 32, :ok}, {:var, 32, :Body}, {:var, 32, :_}]},
                 {:call, 32,
                  {:remote, 32, {:atom, 32, :cowboy_req}, {:atom, 32, :read_urlencoded_body}},
                  [{:var, 32, :Req}]}},
                {:call, 33, {:remote, 33, {:atom, 33, :lists}, {:atom, 33, :keyfind}},
                 [{:var, 33, :Key}, {:integer, 33, 1}, {:var, 33, :Body}]}
              ]}
           ]},
          {:function, 36, :from_url, 2,
           [
             {:clause, 36, [{:var, 36, :Req}, {:var, 36, :Key}], [],
              [
                {:call, 38, {:remote, 38, {:atom, 38, :cowboy_req}, {:atom, 38, :binding}},
                 [{:var, 38, :Key}, {:var, 38, :Req}]}
              ]}
           ]}
        ]
      )

      test_construct(
        {:list,
         [
           {:symbol, "handler", 1},
           {:symbol, "A", 1},
           {:hashmap, %{{:symbol, "NOT_ALLOWED", 1} => {:symbol, "a", 1}}, 1}
         ], 1},
        [
          {:attribute, 0, :module, :A},
          {:attribute, 2, :export, [init: 2]},
          {:function, 5, :init, 2,
           [
             {:clause, 6, [{:var, 6, :Req}, {:var, 6, :_state}], [],
              [
                {:call, 8, {:atom, 8, :handle_req},
                 [
                   {:call, 9, {:remote, 9, {:atom, 9, :maps}, {:atom, 9, :get}},
                    [{:atom, 9, :method}, {:var, 9, :Req}]},
                   {:var, 9, :Req}
                 ]}
              ]}
           ]},
          {:function, 11, :handle_req, 2,
           [
             {:clause, 14, [{:var, 14, :_}, {:var, 14, :Req}], [],
              [
                {:call, 16, {:remote, 16, {:atom, 16, :cowboy_req}, {:atom, 16, :reply}},
                 [{:integer, 16, 404}, {:var, 16, :Req}]}
              ]}
           ]},
          {:function, 21, :reply_json, 3,
           [
             {:clause, 22, [{:var, 22, :Req}, {:var, 22, :Body}, {:var, 22, :Status}], [],
              [
                {:call, 24, {:remote, 24, {:atom, 24, :cowboy_req}, {:atom, 24, :reply}},
                 [
                   {:var, 24, :Status},
                   {:map, 24,
                    [
                      {:map_field_assoc, 24,
                       {:bin, 24,
                        [{:bin_element, 24, {:string, 24, 'content-type'}, :default, :default}]},
                       {:bin, 24,
                        [
                          {:bin_element, 24, {:string, 24, 'application/json'}, :default,
                           :default}
                        ]}}
                    ]},
                   {:call, 24, {:remote, 24, {:atom, 24, :jsone}, {:atom, 24, :encode}},
                    [{:var, 24, :Body}]},
                   {:var, 24, :Req}
                 ]}
              ]}
           ]},
          {:function, 26, :from_body, 2,
           [
             {:clause, 26, [{:var, 26, :Req}, {:var, 26, :Key}], [],
              [
                {:match, 28, {:tuple, 28, [{:atom, 28, :ok}, {:var, 28, :Body}, {:var, 28, :_}]},
                 {:call, 28,
                  {:remote, 28, {:atom, 28, :cowboy_req}, {:atom, 28, :read_urlencoded_body}},
                  [{:var, 28, :Req}]}},
                {:call, 29, {:remote, 29, {:atom, 29, :lists}, {:atom, 29, :keyfind}},
                 [{:var, 29, :Key}, {:integer, 29, 1}, {:var, 29, :Body}]}
              ]}
           ]},
          {:function, 32, :from_url, 2,
           [
             {:clause, 32, [{:var, 32, :Req}, {:var, 32, :Key}], [],
              [
                {:call, 34, {:remote, 34, {:atom, 34, :cowboy_req}, {:atom, 34, :binding}},
                 [{:var, 34, :Key}, {:var, 34, :Req}]}
              ]}
           ]}
        ]
      )
    end

    test "rest_app" do
      test_construct(
        {:list,
         [
           {:symbol, "rest_app", 1},
           {:symbol, "A", 1},
           {:integer, 8080, 1},
           {:hashmap, %{{:string, "/a", 1} => {:atom, :handler, 1}}, 1},
           {:symbol, "before", 1}
         ], 1},
        [
          {:attribute, 0, :module, :A},
          {:attribute, 2, :export, [start: 2]},
          {:function, 5, :start, 2,
           [
             {:clause, 5, [{:var, 5, :_}, {:var, 5, :_}], [],
              [
                {:call, 6, {:atom, 6, :before}, []},
                {:match, 7, {:var, 7, :Dispatch},
                 {:call, 7, {:remote, 7, {:atom, 7, :cowboy_router}, {:atom, 7, :compile}},
                  [
                    {:cons, 7,
                     {:tuple, 7,
                      [
                        {:atom, 7, :_},
                        {:cons, 7,
                         {:tuple, 8, [{:string, 8, '/a'}, {:atom, 8, :handler}, {:map, 8, []}]},
                         {nil, 7}}
                      ]}, {nil, 7}}
                  ]}},
                {:call, 10, {:remote, 10, {:atom, 10, :cowboy}, {:atom, 10, :start_clear}},
                 [
                   {:atom, 10, :todo_listener},
                   {:cons, 10, {:tuple, 10, [{:atom, 10, :port}, {:integer, 10, 8080}]},
                    {nil, 10}},
                   {:map, 10,
                    [
                      {:map_field_assoc, 10, {:atom, 10, :env},
                       {:map, 10,
                        [{:map_field_assoc, 10, {:atom, 10, :dispatch}, {:var, 10, :Dispatch}}]}}
                    ]}
                 ]},
                {:tuple, 11, [{:atom, 11, :ok}, {:call, 11, {:atom, 11, :self}, []}]}
              ]}
           ]}
        ]
      )

      test_construct(
        {:list,
         [
           {:symbol, "rest_app", 1},
           {:symbol, "A", 1},
           {:integer, 8080, 1},
           {:hashmap, %{{:string, "/a", 1} => {:atom, :handler, 1}}, 1},
           {:erlang_remote, "before", "do", 1}
         ], 1},
        [
          {:attribute, 0, :module, :A},
          {:attribute, 2, :export, [start: 2]},
          {:function, 5, :start, 2,
           [
             {:clause, 5, [{:var, 5, :_}, {:var, 5, :_}], [],
              [
                {:call, 6, {:remote, 6, {:atom, 6, :before}, {:atom, 6, :do}}, []},
                {:match, 7, {:var, 7, :Dispatch},
                 {:call, 7, {:remote, 7, {:atom, 7, :cowboy_router}, {:atom, 7, :compile}},
                  [
                    {:cons, 7,
                     {:tuple, 7,
                      [
                        {:atom, 7, :_},
                        {:cons, 7,
                         {:tuple, 8, [{:string, 8, '/a'}, {:atom, 8, :handler}, {:map, 8, []}]},
                         {nil, 7}}
                      ]}, {nil, 7}}
                  ]}},
                {:call, 10, {:remote, 10, {:atom, 10, :cowboy}, {:atom, 10, :start_clear}},
                 [
                   {:atom, 10, :todo_listener},
                   {:cons, 10, {:tuple, 10, [{:atom, 10, :port}, {:integer, 10, 8080}]},
                    {nil, 10}},
                   {:map, 10,
                    [
                      {:map_field_assoc, 10, {:atom, 10, :env},
                       {:map, 10,
                        [{:map_field_assoc, 10, {:atom, 10, :dispatch}, {:var, 10, :Dispatch}}]}}
                    ]}
                 ]},
                {:tuple, 11, [{:atom, 11, :ok}, {:call, 11, {:atom, 11, :self}, []}]}
              ]}
           ]}
        ]
      )

      test_construct(
        {:list,
         [
           {:symbol, "rest_app", 1},
           {:symbol, "A", 1},
           {:integer, 8080, 1},
           {:hashmap, %{{:string, "/a", 1} => {:atom, :handler, 1}}, 1}
         ], 1},
        [
          {:attribute, 0, :module, :A},
          {:attribute, 2, :export, [start: 2]},
          {:function, 5, :start, 2,
           [
             {:clause, 5, [{:var, 5, :_}, {:var, 5, :_}], [],
              [
                {:match, 7, {:var, 7, :Dispatch},
                 {:call, 7, {:remote, 7, {:atom, 7, :cowboy_router}, {:atom, 7, :compile}},
                  [
                    {:cons, 7,
                     {:tuple, 7,
                      [
                        {:atom, 7, :_},
                        {:cons, 7,
                         {:tuple, 8, [{:string, 8, '/a'}, {:atom, 8, :handler}, {:map, 8, []}]},
                         {nil, 7}}
                      ]}, {nil, 7}}
                  ]}},
                {:call, 10, {:remote, 10, {:atom, 10, :cowboy}, {:atom, 10, :start_clear}},
                 [
                   {:atom, 10, :todo_listener},
                   {:cons, 10, {:tuple, 10, [{:atom, 10, :port}, {:integer, 10, 8080}]},
                    {nil, 10}},
                   {:map, 10,
                    [
                      {:map_field_assoc, 10, {:atom, 10, :env},
                       {:map, 10,
                        [{:map_field_assoc, 10, {:atom, 10, :dispatch}, {:var, 10, :Dispatch}}]}}
                    ]}
                 ]},
                {:tuple, 11, [{:atom, 11, :ok}, {:call, 11, {:atom, 11, :self}, []}]}
              ]}
           ]}
        ]
      )
    end

    test "defn" do
      test_construct(
        {:list,
         [
           {:symbol, "defn", 1},
           {:symbol, "A", 1},
           {:list, [{:var, :a, 1}], 1},
           {:list, [{:var, :a, 1}], 1}
         ], 1},
        {:function, 1, :A, 1, [{:clause, 1, [{:var, 1, :A}], [], [{:var, 1, :A}]}]}
      )

      test_construct(
        {:list,
         [
           {:symbol, "defn", 1},
           {:symbol, "A", 1},
           {:list, [], 1},
           {:list, [], 1}
         ], 1},
        {:function, 1, :A, 0, [{:clause, 1, [], [], []}]}
      )
    end

    test "raises when unexpected symbol received" do
      assert_raise RuntimeError, fn -> Parser.parse_forms([{:symbol, "A", 1}]) end
    end
  end

  defp test_construct(payload, result) do
    assert {:ok, [{:cons, 0, result, {nil, 0}}]} == Parser.parse_forms([{:list, [payload], 0}])
  end
end
