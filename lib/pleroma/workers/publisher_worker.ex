# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Workers.PublisherWorker do
  alias Pleroma.Activity
  alias Pleroma.Web.Federator

  use Pleroma.Workers.WorkerHelper, queue: "federator_outgoing"

  def backoff(%Job{attempt: attempt}) when is_integer(attempt) do
    Pleroma.Workers.WorkerHelper.sidekiq_backoff(attempt, 5)
  end

  @impl Oban.Worker
  def perform(%Job{args: %{"op" => "publish", "activity_id" => activity_id}}) do
    activity = Activity.get_by_id(activity_id)
    Federator.perform(:publish, activity)
  end

  def perform(%Job{args: %{"op" => "publish_one", "params" => params}}) do
    params = Map.new(params, fn {k, v} -> {String.to_atom(k), v} end)
    Federator.perform(:publish_one, params)
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.seconds(10)
end
