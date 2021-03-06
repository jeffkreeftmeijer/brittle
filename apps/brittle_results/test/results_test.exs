defmodule Brittle.ResultsTest do
  use ExUnit.Case, async: true
  alias Brittle.{Repo, Results, Suite, Run, Result, Test}
  import Brittle.Fixtures

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Brittle.Repo)

    [attributes: attributes(:run)]
  end

  test "create_run/1 creates a run", %{attributes: attributes} do
    {:ok, %Run{} = run} = Results.create_run(attributes)

    assert run.hostname == "Alices-MBP.fritz.box"
    assert run.branch == "master"
    assert run.revision == "df54993999a5b340c8d3949e526ae91dba09a351"
    assert run.dirty == false
    assert run.test_count == 617
    assert run.failure_count == 0
    assert run.excluded_count == 4
    assert run.duration == 20713727
    assert run.started_at == DateTime.from_naive!(~N[2018-05-01 21:33:11.449706], "Etc/UTC")
    assert run.finished_at == DateTime.from_naive!(~N[2018-05-01 21:33:32.163448], "Etc/UTC")
  end

  test "create_run/1 does not create the same run twice", %{attributes: attributes} do
    assert {:ok, %Run{id: id}} = Results.create_run(attributes)
    assert {:ok, %Run{id: ^id}} = Results.create_run(attributes)
  end

  test "create_run/1 creates a suite", %{attributes: attributes} do
    {:ok, %Run{suite: %Suite{} = suite}} = Results.create_run(attributes)

    assert suite.name == "phoenix"
  end

  test "create_run/1 links runs to existing suites", %{attributes: attributes} do
    %Suite{id: id} = Repo.insert!(%Suite{name: "phoenix"})

    assert {:ok, %Run{suite_id: ^id}} = Results.create_run(attributes)
  end

  test "create_run/1 creates a result", %{attributes: attributes} do
    {:ok, %Run{results: [%Result{} = result | _]}} = Results.create_run(attributes)

    assert result.status == "passed"
    assert result.duration == 313727
  end

  test "create_run/1 creates a test", %{attributes: attributes} do
    {:ok,
     %Run{suite: suite, results: [%Result{test: %Test{} = test} | _]}} =
      Results.create_run(attributes)

    assert test.suite_id == suite.id
    assert test.module == "Elixir.ExampleTest"
    assert test.name == "test passes"
    assert test.file == "test/example_test.exs"
    assert test.line == 12
  end

  test "create_run/1 links results to existing tests", %{attributes: attributes} do
    {:ok, %Run{results: [%Result{test: %Test{id: id}} | _]}} =
      Results.create_run(attributes)

    {:ok, %Run{results: [%Result{test: %Test{id: ^id}} | _]}} =
      Results.create_run(attributes(:failed_run))
  end

  describe "for a failed run" do
    setup do
      [attributes: attributes(:failed_run)]
    end

    test "create_run/1 creates failures for failed results", %{
      attributes: attributes
    } do
      {:ok, %Run{results: [%Result{failures: [failure | _]} | _]}} =
        Results.create_run(attributes)

      assert failure.message == "Assertion with == failed"
      assert failure.code == "assert true == false"

      assert failure.stacktrace ==
               "    test/ex_unit_data_test.exs:30: ExampleTest.\"test fails\"/1\n"
    end
  end
end
