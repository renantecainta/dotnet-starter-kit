using FSH.Modules.Auditing.Contracts;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace FSH.Modules.Auditing;

public sealed class SystemTextJsonAuditSerializer : IAuditSerializer
{
    private static readonly JsonSerializerOptions Opts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        Converters = { new JsonStringEnumConverter() },
        WriteIndented = false,
        MaxDepth = 32
    };

    private const int MaxPayloadLength = 1_000_000;

    public string SerializePayload(object payload)
    {
        if (payload is null)
            return string.Empty;

        var json = JsonSerializer.Serialize(payload, Opts);

        if (json.Length > MaxPayloadLength)
        {
            return json[..MaxPayloadLength];
        }

        return json;
    }
}