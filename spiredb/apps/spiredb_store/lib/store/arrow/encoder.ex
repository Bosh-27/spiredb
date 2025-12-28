defmodule Store.Arrow.Encoder do
  @moduledoc """
  Encode rows as Apache Arrow RecordBatch using Explorer library.

  Provides zero-copy data transfer to SpireSQL (Rust) using Arrow's
  binary IPC format via the Explorer DataFrame library.
  """

  require Logger
  alias Explorer.DataFrame, as: DF
  alias Explorer.Series

  @doc """
  Encode scan results as Arrow RecordBatch IPC stream.

  Schema: [key: Binary, value: Binary]

  Returns binary in Arrow IPC stream format.
  """
  def encode_scan_batch(rows) when is_list(rows) do
    if rows == [] do
      # Return empty Arrow stream
      encode_empty_scan_batch()
    else
      # Extract keys and values
      keys = Enum.map(rows, fn {k, _v} -> k end)
      values = Enum.map(rows, fn {_k, v} -> v end)

      # Create DataFrame with binary series
      df =
        DF.new(%{
          "key" => Series.from_list(keys, dtype: :binary),
          "value" => Series.from_list(values, dtype: :binary)
        })

      # Export as Arrow IPC stream (returns binary)
      {:ok, binary} = DF.dump_ipc_stream(df)
      binary
    end
  rescue
    error ->
      Logger.error("Failed to encode scan batch",
        error: inspect(error),
        rows_count: length(rows)
      )

      {:error, :encoding_failed}
  end

  @doc """
  Encode batch get results as Arrow RecordBatch IPC stream.

  Schema: [key: Binary, value: Binary, found: Boolean]

  Returns binary in Arrow IPC stream format.
  """
  def encode_batch_get_result(results) when is_list(results) do
    if results == [] do
      encode_empty_batch_get()
    else
      # Extract keys, values, and found flags
      keys = Enum.map(results, fn {k, _v, _f} -> k end)
      values = Enum.map(results, fn {_k, v, _f} -> v end)
      founds = Enum.map(results, fn {_k, _v, f} -> f end)

      # Create DataFrame (column order matters for tests)
      df =
        DF.new(
          %{
            "key" => Series.from_list(keys, dtype: :binary),
            "value" => Series.from_list(values, dtype: :binary),
            "found" => Series.from_list(founds, dtype: :boolean)
          },
          dtypes: [{"key", :binary}, {"value", :binary}, {"found", :boolean}]
        )

      # Export as Arrow IPC stream
      {:ok, binary} = DF.dump_ipc_stream(df)
      binary
    end
  rescue
    error ->
      Logger.error("Failed to encode batch get result",
        error: inspect(error),
        results_count: length(results)
      )

      {:error, :encoding_failed}
  end

  # Private helpers

  defp encode_empty_scan_batch do
    df =
      DF.new(%{
        "key" => Series.from_list([], dtype: :binary),
        "value" => Series.from_list([], dtype: :binary)
      })

    {:ok, binary} = DF.dump_ipc_stream(df)
    binary
  end

  defp encode_empty_batch_get do
    df =
      DF.new(
        %{
          "key" => Series.from_list([], dtype: :binary),
          "value" => Series.from_list([], dtype: :binary),
          "found" => Series.from_list([], dtype: :boolean)
        },
        dtypes: [{"key", :binary}, {"value", :binary}, {"found", :boolean}]
      )

    {:ok, binary} = DF.dump_ipc_stream(df)
    binary
  end
end
