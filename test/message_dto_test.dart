import 'dart:convert';

import 'package:carbon_voice_console/features/messages/data/models/api/message_dto.dart';
import 'package:carbon_voice_console/features/messages/data/models/api/message_dto_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MessageDto can parse the provided JSON and convert to domain', () {
    const jsonString = '''
{
  "deleted_at": null,
  "parent_message_id": null,
  "heard_ms": 50064,
  "utm_data": {
    "utm_source": null,
    "utm_medium": null,
    "utm_campaign": null,
    "utm_term": null,
    "utm_content": null
  },
  "name": null,
  "source_message_id": null,
  "message_id": "1e054a70-c736-11f0-bea8-25c1d20899c8",
  "creator_id": "travis",
  "created_at": "2025-11-21T23:59:30.373Z",
  "last_updated_at": "2025-11-22T00:04:12.870Z",
  "workspace_ids": ["personal"],
  "channel_ids": ["6920fcda28dfa93b2254242c"],
  "duration_ms": 50064,
  "attachments": [],
  "notes": "",
  "notify": false,
  "last_heard_update": "2025-11-22T00:04:12.870Z",
  "reaction_summary": {
    "reaction_counts": {},
    "top_user_reactions": []
  },
  "is_text_message": false,
  "status": "active",
  "label_ids": [],
  "audio_models": [
    {
      "_id": "6920fce268581f44f69115c4",
      "url": "https://api.carbonvoice.app/stream/1e054a70-c736-11f0-bea8-25c1d20899c8/stream.m3u8",
      "streaming": true,
      "language": "english",
      "duration_ms": 50064,
      "waveform_percentages": [0.082, 0.082, 0.228, 1, 0.95, 0.914, 0.905, 0.842, 0.689, 0.766, 0.801, 0.803, 0.186, 0.488, 0.947, 0.806, 0.764, 0.804, 0.89, 0.85, 0.781, 0.744, 0.924, 0.836, 0.792, 0.846, 0.862, 0.767, 0.749, 0.739, 0.775, 0.708, 0.71, 0.283, 0.842, 0.748, 0.682, 0.868, 0.933, 1, 0.812, 0.866, 0.835, 0.979, 0.955, 0.946, 0.98, 0.87, 0.745, 0.945, 0.146, 0.961, 0.969, 0.987, 0.89, 0.971, 0.914, 0.893, 0.936, 0.842, 0.911, 0.887, 0.952, 0.894, 0.765, 0.781, 0.577, 0.852, 0.802, 0.905, 0.911, 0.429, 0.912, 0.928, 0.808, 0.877, 0.914, 0.825, 0.687, 0.435, 0.804, 0.96, 0.844, 0.878, 0.817, 0.765, 0.92, 0.88, 0.938, 0.832, 0.968, 0.984, 0.902, 0.892, 0.82, 0.845, 0.683, 0.875, 0.999, 0.383, 0.988, 0.705, 0.961, 0.877, 0.876, 0.977, 0.978, 0.92, 0.944, 0.922, 0.82, 0.846, 0.74, 0.768, 0.676, 0.745, 0.746, 0.602, 0.827],
      "is_original_audio": true,
      "extension": "m3u8"
    },
    {
      "_id": "6920fd16f6bee6ac23bf5281",
      "url": "https://api.carbonvoice.app/stream/1e054a70-c736-11f0-bea8-25c1d20899c8/6920fd16f6bee6ac23bf5281/audio.mp3",
      "streaming": false,
      "language": "english",
      "duration_ms": 50064,
      "waveform_percentages": [0.082, 0.082, 0.228, 1, 0.95, 0.914, 0.905, 0.842, 0.689, 0.766, 0.801, 0.803, 0.186, 0.488, 0.947, 0.806, 0.764, 0.804, 0.89, 0.85, 0.781, 0.744, 0.924, 0.836, 0.792, 0.846, 0.862, 0.767, 0.749, 0.739, 0.775, 0.708, 0.71, 0.283, 0.842, 0.748, 0.682, 0.868, 0.933, 1, 0.812, 0.866, 0.835, 0.979, 0.955, 0.946, 0.98, 0.87, 0.745, 0.945, 0.146, 0.961, 0.969, 0.987, 0.89, 0.971, 0.914, 0.893, 0.936, 0.842, 0.911, 0.887, 0.952, 0.894, 0.765, 0.781, 0.577, 0.852, 0.802, 0.905, 0.911, 0.429, 0.912, 0.928, 0.808, 0.877, 0.914, 0.825, 0.687, 0.435, 0.804, 0.96, 0.844, 0.878, 0.817, 0.765, 0.92, 0.88, 0.938, 0.832, 0.968, 0.984, 0.902, 0.892, 0.82, 0.845, 0.683, 0.875, 0.999, 0.383, 0.988, 0.705, 0.961, 0.877, 0.876, 0.977, 0.978, 0.92, 0.944, 0.922, 0.82, 0.846, 0.74, 0.768, 0.676, 0.745, 0.746, 0.602, 0.827],
      "is_original_audio": true,
      "extension": "mp3"
    }
  ],
  "text_models": [
    {
      "type": "transcript_with_timecode",
      "audio_id": "6920fd16f6bee6ac23bf5281",
      "language_id": "english",
      "value": "",
      "timecodes": [
        {"t": "Hey,,", "s": 1240, "e": 1399},
        {"t": "Christian.", "s": 1419, "e": 1919},
        {"t": "Hope", "s": 1919, "e": 2119},
        {"t": "all", "s": 2119, "e": 2240},
        {"t": "is", "s": 2240, "e": 2359},
        {"t": "well.", "s": 2460, "e": 2880},
        {"t": "I,,", "s": 2980, "e": 3420},
        {"t": "um,,", "s": 3519, "e": 3759},
        {"t": "think", "s": 3920, "e": 4199},
        {"t": "that,,", "s": 4239, "e": 4579},
        {"t": "uh,,", "s": 4639, "e": 4779},
        {"t": "uh,,", "s": 5940, "e": 6039},
        {"t": "Thomas", "s": 6119, "e": 6419},
        {"t": "made", "s": 6460, "e": 6619},
        {"t": "me", "s": 6619, "e": 6719},
        {"t": "mention", "s": 6739, "e": 6980},
        {"t": "I'd", "s": 7039, "e": 7219},
        {"t": "be", "s": 7239, "e": 7359},
        {"t": "reaching", "s": 7379, "e": 7659},
        {"t": "out.", "s": 7679, "e": 8179},
        {"t": "I'm", "s": 8239, "e": 8399},
        {"t": "the", "s": 8440, "e": 8600},
        {"t": "founder", "s": 8699, "e": 8980},
        {"t": "and", "s": 8980, "e": 9039},
        {"t": "CEO", "s": 9159, "e": 9320},
        {"t": "of", "s": 9340, "e": 9420},
        {"t": "Carbon", "s": 9479, "e": 9699},
        {"t": "Voice,,", "s": 9739, "e": 10079},
        {"t": "and,,", "s": 10380, "e": 10739},
        {"t": "uh,,", "s": 10779, "e": 10939},
        {"t": "he", "s": 11079, "e": 11199},
        {"t": "mentioned", "s": 11279, "e": 11699},
        {"t": "that", "s": 11739, "e": 11880},
        {"t": "you", "s": 12039, "e": 12459},
        {"t": "were", "s": 12520, "e": 12739},
        {"t": "looking", "s": 12800, "e": 13199},
        {"t": "to,,", "s": 13279, "e": 14359},
        {"t": "um,,", "s": 14460, "e": 14979},
        {"t": "you", "s": 15439, "e": 15479},
        {"t": "know,,", "s": 15480, "e": 15619},
        {"t": "con-", "s": 15639, "e": 16039},
        {"t": "find", "s": 16219, "e": 16379},
        {"t": "projects", "s": 16459, "e": 16819},
        {"t": "as", "s": 16879, "e": 16980},
        {"t": "you", "s": 17020, "e": 17120},
        {"t": "sorta", "s": 17159, "e": 17359},
        {"t": "continue", "s": 17399, "e": 17739},
        {"t": "to", "s": 17739, "e": 17819},
        {"t": "learn", "s": 17860, "e": 18059},
        {"t": "and", "s": 18059, "e": 18159},
        {"t": "develop.", "s": 18180, "e": 18659},
        {"t": "But", "s": 18659, "e": 18899},
        {"t": "maybe,,", "s": 18979, "e": 19560},
        {"t": "um,,", "s": 19619, "e": 20460},
        {"t": "uh,,", "s": 20520, "e": 20719},
        {"t": "you", "s": 21439, "e": 21639},
        {"t": "know,,", "s": 21639, "e": 21780},
        {"t": "I", "s": 21800, "e": 21840},
        {"t": "was", "s": 22020, "e": 22139},
        {"t": "telling", "s": 22199, "e": 22399},
        {"t": "him,,", "s": 22459, "e": 22659},
        {"t": "I", "s": 22659, "e": 22719},
        {"t": "was", "s": 22719, "e": 22840},
        {"t": "like,,", "s": 22879, "e": 23039},
        {"t": "Hey,,", "s": 23079, "e": 23279},
        {"t": "I", "s": 23340, "e": 23380},
        {"t": "have", "s": 23399, "e": 23500},
        {"t": "a", "s": 23539, "e": 23599},
        {"t": "thousand", "s": 23659, "e": 23979},
        {"t": "ideas", "s": 24059, "e": 24319},
        {"t": "of", "s": 24340, "e": 24499},
        {"t": "things", "s": 24500, "e": 24800},
        {"t": "to", "s": 24860, "e": 25000},
        {"t": "build.", "s": 25059, "e": 25860},
        {"t": "Um,,", "s": 25899, "e": 26260},
        {"t": "so,,", "s": 26600, "e": 27159},
        {"t": "um,,", "s": 27239, "e": 27739},
        {"t": "would", "s": 28219, "e": 28599},
        {"t": "love", "s": 29019, "e": 29180},
        {"t": "to,,", "s": 29239, "e": 30059},
        {"t": "you", "s": 30059, "e": 30100},
        {"t": "know,,", "s": 30120, "e": 30279},
        {"t": "open", "s": 30380, "e": 30559},
        {"t": "to", "s": 30579, "e": 30680},
        {"t": "have,,", "s": 30700, "e": 30979},
        {"t": "having", "s": 31000, "e": 31199},
        {"t": "the", "s": 31199, "e": 31280},
        {"t": "conversation", "s": 31300, "e": 31719},
        {"t": "about", "s": 31779, "e": 31979},
        {"t": "what,,", "s": 32020, "e": 32380},
        {"t": "um,,", "s": 32459, "e": 33159},
        {"t": "uh,,", "s": 33200, "e": 33479},
        {"t": "you", "s": 33619, "e": 33659},
        {"t": "know,,", "s": 33680, "e": 33759},
        {"t": "what,,", "s": 33799, "e": 34000},
        {"t": "what", "s": 34020, "e": 34139},
        {"t": "types", "s": 34139, "e": 34340},
        {"t": "of", "s": 34360, "e": 34400},
        {"t": "things", "s": 34439, "e": 34599},
        {"t": "are", "s": 34619, "e": 34700},
        {"t": "interesting,,", "s": 34720, "e": 35199},
        {"t": "what,,", "s": 35220, "e": 35419},
        {"t": "what", "s": 35419, "e": 35520},
        {"t": "you're", "s": 35599, "e": 35700},
        {"t": "trying", "s": 35700, "e": 35840},
        {"t": "to", "s": 35860, "e": 35919},
        {"t": "build,,", "s": 35959, "e": 36159},
        {"t": "what", "s": 36180, "e": 36259},
        {"t": "you're", "s": 36279, "e": 36380},
        {"t": "trying", "s": 36400, "e": 36560},
        {"t": "to", "s": 36580, "e": 36639},
        {"t": "learn,,", "s": 36700, "e": 37459},
        {"t": "uh,,", "s": 37500, "e": 37540},
        {"t": "what", "s": 37600, "e": 37700},
        {"t": "areas", "s": 37799, "e": 38000},
        {"t": "of", "s": 38000, "e": 38099},
        {"t": "the", "s": 38119, "e": 38200},
        {"t": "stack", "s": 38220, "e": 38540},
        {"t": "you're", "s": 38560, "e": 38700},
        {"t": "willing", "s": 38700, "e": 38840},
        {"t": "to", "s": 38860, "e": 38939},
        {"t": "dive", "s": 38979, "e": 39180},
        {"t": "into,,", "s": 39200, "e": 39500},
        {"t": "and", "s": 39520, "e": 39619},
        {"t": "play", "s": 39659, "e": 39779},
        {"t": "around", "s": 39819, "e": 40020},
        {"t": "with,,", "s": 40060, "e": 40220},
        {"t": "and", "s": 40240, "e": 40299},
        {"t": "do", "s": 40340, "e": 40459},
        {"t": "stuff", "s": 40500, "e": 40720},
        {"t": "with.", "s": 40760, "e": 41060},
        {"t": "So,,", "s": 41080, "e": 41779},
        {"t": "um,,", "s": 41879, "e": 42119},
        {"t": "let's", "s": 42799, "e": 43259},
        {"t": "maybe", "s": 43379, "e": 43560},
        {"t": "just", "s": 43659, "e": 43779},
        {"t": "start", "s": 43819, "e": 44099},
        {"t": "by", "s": 44180, "e": 44459},
        {"t": "telling", "s": 44520, "e": 44739},
        {"t": "me", "s": 44759, "e": 44819},
        {"t": "a", "s": 44860, "e": 44920},
        {"t": "little", "s": 44959, "e": 45099},
        {"t": "about", "s": 45180, "e": 45399},
        {"t": "yourself,,", "s": 45439, "e": 45900},
        {"t": "what", "s": 45919, "e": 46040},
        {"t": "you've", "s": 46060, "e": 46139},
        {"t": "been", "s": 46159, "e": 46259},
        {"t": "building,,", "s": 46340, "e": 47040},
        {"t": "uh,,", "s": 47100, "e": 47340},
        {"t": "what", "s": 47439, "e": 47540},
        {"t": "you're", "s": 47619, "e": 47959},
        {"t": "trying", "s": 48000, "e": 48259},
        {"t": "to,,", "s": 48279, "e": 48880},
        {"t": "um,,", "s": 48959, "e": 49239},
        {"t": "go", "s": 49459, "e": 49540},
        {"t": "after.", "s": 49599, "e": 49979}
      ]
    },
    {
      "type": "summary",
      "audio_id": "6920fd16f6bee6ac23bf5281",
      "language_id": "english",
      "value": "Hi Christian, Thomas asked me to reach out. I'm Carbon Voice's founder/CEO with a thousand ideas; I'd love to discuss your goals and collaboration.",
      "timecodes": []
    }
  ],
  "cache_key": "production-20231017",
  "audio_delivery": "streaming",
  "notified_users": 0,
  "total_heard_ms": 100128,
  "users_caught_up": "all",
  "forward_id": null,
  "share_link_id": null,
  "socket_disconnects_while_streaming": 0,
  "stream_key": null,
  "type": "channel",
  "channel_sequence": 1,
  "last_heard_at": "2025-11-22T00:04:42.870Z",
  "folder_id": null
}
''';

    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final dto = MessageDto.fromJson(json);

    // Verify DTO parsing
    expect(dto.messageId, '1e054a70-c736-11f0-bea8-25c1d20899c8');
    expect(dto.creatorId, 'travis');
    expect(dto.audioModels.length, 2);
    expect(dto.textModels.length, 2);

    // Convert to domain and verify
    final message = dto.toDomain();
    expect(message.id, '1e054a70-c736-11f0-bea8-25c1d20899c8');
    expect(message.creatorId, 'travis');
    expect(message.audioModels.length, 2);
    expect(message.transcripts.length, 2);
    expect(message.streamingAudioModel?.format, 'm3u8');
    expect(message.audioModels.where((model) => !model.isStreaming).first.format, 'mp3');
    expect(message.transcriptWithTimecodes?.timecodes.isNotEmpty, true);
    expect(message.summaryTranscript?.text,
        "Hi Christian, Thomas asked me to reach out. I'm Carbon Voice's founder/CEO with a thousand ideas; I'd love to discuss your goals and collaboration.");
  });
}
