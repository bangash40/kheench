// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, Download> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteMeta = const VerificationMeta('site');
  @override
  late final GeneratedColumn<String> site = GeneratedColumn<String>(
    'site',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailMeta = const VerificationMeta(
    'thumbnail',
  );
  @override
  late final GeneratedColumn<String> thumbnail = GeneratedColumn<String>(
    'thumbnail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
    'quality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectorMeta = const VerificationMeta(
    'selector',
  );
  @override
  late final GeneratedColumn<String> selector = GeneratedColumn<String>(
    'selector',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extraArgsMeta = const VerificationMeta(
    'extraArgs',
  );
  @override
  late final GeneratedColumn<String> extraArgs = GeneratedColumn<String>(
    'extra_args',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _partsMeta = const VerificationMeta('parts');
  @override
  late final GeneratedColumn<int> parts = GeneratedColumn<int>(
    'parts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentMeta = const VerificationMeta(
    'percent',
  );
  @override
  late final GeneratedColumn<double> percent = GeneratedColumn<double>(
    'percent',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
    'uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    url,
    title,
    site,
    thumbnail,
    durationSec,
    kind,
    quality,
    selector,
    extraArgs,
    parts,
    status,
    percent,
    uri,
    filePath,
    mime,
    sizeBytes,
    error,
    createdAt,
    finishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<Download> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('site')) {
      context.handle(
        _siteMeta,
        site.isAcceptableOrUnknown(data['site']!, _siteMeta),
      );
    } else if (isInserting) {
      context.missing(_siteMeta);
    }
    if (data.containsKey('thumbnail')) {
      context.handle(
        _thumbnailMeta,
        thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    } else if (isInserting) {
      context.missing(_qualityMeta);
    }
    if (data.containsKey('selector')) {
      context.handle(
        _selectorMeta,
        selector.isAcceptableOrUnknown(data['selector']!, _selectorMeta),
      );
    } else if (isInserting) {
      context.missing(_selectorMeta);
    }
    if (data.containsKey('extra_args')) {
      context.handle(
        _extraArgsMeta,
        extraArgs.isAcceptableOrUnknown(data['extra_args']!, _extraArgsMeta),
      );
    }
    if (data.containsKey('parts')) {
      context.handle(
        _partsMeta,
        parts.isAcceptableOrUnknown(data['parts']!, _partsMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('percent')) {
      context.handle(
        _percentMeta,
        percent.isAcceptableOrUnknown(data['percent']!, _percentMeta),
      );
    }
    if (data.containsKey('uri')) {
      context.handle(
        _uriMeta,
        uri.isAcceptableOrUnknown(data['uri']!, _uriMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Download map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Download(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      site: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site'],
      )!,
      thumbnail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality'],
      )!,
      selector: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selector'],
      )!,
      extraArgs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra_args'],
      )!,
      parts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parts'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      percent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}percent'],
      ),
      uri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uri'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      mime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }
}

class Download extends DataClass implements Insertable<Download> {
  final String id;
  final String url;
  final String title;
  final String site;
  final String? thumbnail;
  final int? durationSec;

  /// `video` or `audio`.
  final String kind;

  /// e.g. `1080p60 MP4`, `MP3 audio`.
  final String quality;
  final String selector;

  /// Extra yt-dlp arguments, one per line.
  final String extraArgs;
  final int parts;
  final String status;

  /// Last known progress (0–100), kept so a paused download shows where it stopped.
  final double? percent;
  final String? uri;
  final String? filePath;
  final String? mime;
  final int? sizeBytes;
  final String? error;
  final DateTime createdAt;
  final DateTime? finishedAt;
  const Download({
    required this.id,
    required this.url,
    required this.title,
    required this.site,
    this.thumbnail,
    this.durationSec,
    required this.kind,
    required this.quality,
    required this.selector,
    required this.extraArgs,
    required this.parts,
    required this.status,
    this.percent,
    this.uri,
    this.filePath,
    this.mime,
    this.sizeBytes,
    this.error,
    required this.createdAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['url'] = Variable<String>(url);
    map['title'] = Variable<String>(title);
    map['site'] = Variable<String>(site);
    if (!nullToAbsent || thumbnail != null) {
      map['thumbnail'] = Variable<String>(thumbnail);
    }
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    map['kind'] = Variable<String>(kind);
    map['quality'] = Variable<String>(quality);
    map['selector'] = Variable<String>(selector);
    map['extra_args'] = Variable<String>(extraArgs);
    map['parts'] = Variable<int>(parts);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || percent != null) {
      map['percent'] = Variable<double>(percent);
    }
    if (!nullToAbsent || uri != null) {
      map['uri'] = Variable<String>(uri);
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || mime != null) {
      map['mime'] = Variable<String>(mime);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      id: Value(id),
      url: Value(url),
      title: Value(title),
      site: Value(site),
      thumbnail: thumbnail == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnail),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      kind: Value(kind),
      quality: Value(quality),
      selector: Value(selector),
      extraArgs: Value(extraArgs),
      parts: Value(parts),
      status: Value(status),
      percent: percent == null && nullToAbsent
          ? const Value.absent()
          : Value(percent),
      uri: uri == null && nullToAbsent ? const Value.absent() : Value(uri),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      mime: mime == null && nullToAbsent ? const Value.absent() : Value(mime),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      createdAt: Value(createdAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory Download.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Download(
      id: serializer.fromJson<String>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      title: serializer.fromJson<String>(json['title']),
      site: serializer.fromJson<String>(json['site']),
      thumbnail: serializer.fromJson<String?>(json['thumbnail']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
      kind: serializer.fromJson<String>(json['kind']),
      quality: serializer.fromJson<String>(json['quality']),
      selector: serializer.fromJson<String>(json['selector']),
      extraArgs: serializer.fromJson<String>(json['extraArgs']),
      parts: serializer.fromJson<int>(json['parts']),
      status: serializer.fromJson<String>(json['status']),
      percent: serializer.fromJson<double?>(json['percent']),
      uri: serializer.fromJson<String?>(json['uri']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      mime: serializer.fromJson<String?>(json['mime']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      error: serializer.fromJson<String?>(json['error']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'url': serializer.toJson<String>(url),
      'title': serializer.toJson<String>(title),
      'site': serializer.toJson<String>(site),
      'thumbnail': serializer.toJson<String?>(thumbnail),
      'durationSec': serializer.toJson<int?>(durationSec),
      'kind': serializer.toJson<String>(kind),
      'quality': serializer.toJson<String>(quality),
      'selector': serializer.toJson<String>(selector),
      'extraArgs': serializer.toJson<String>(extraArgs),
      'parts': serializer.toJson<int>(parts),
      'status': serializer.toJson<String>(status),
      'percent': serializer.toJson<double?>(percent),
      'uri': serializer.toJson<String?>(uri),
      'filePath': serializer.toJson<String?>(filePath),
      'mime': serializer.toJson<String?>(mime),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'error': serializer.toJson<String?>(error),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  Download copyWith({
    String? id,
    String? url,
    String? title,
    String? site,
    Value<String?> thumbnail = const Value.absent(),
    Value<int?> durationSec = const Value.absent(),
    String? kind,
    String? quality,
    String? selector,
    String? extraArgs,
    int? parts,
    String? status,
    Value<double?> percent = const Value.absent(),
    Value<String?> uri = const Value.absent(),
    Value<String?> filePath = const Value.absent(),
    Value<String?> mime = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    Value<String?> error = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => Download(
    id: id ?? this.id,
    url: url ?? this.url,
    title: title ?? this.title,
    site: site ?? this.site,
    thumbnail: thumbnail.present ? thumbnail.value : this.thumbnail,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
    kind: kind ?? this.kind,
    quality: quality ?? this.quality,
    selector: selector ?? this.selector,
    extraArgs: extraArgs ?? this.extraArgs,
    parts: parts ?? this.parts,
    status: status ?? this.status,
    percent: percent.present ? percent.value : this.percent,
    uri: uri.present ? uri.value : this.uri,
    filePath: filePath.present ? filePath.value : this.filePath,
    mime: mime.present ? mime.value : this.mime,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    error: error.present ? error.value : this.error,
    createdAt: createdAt ?? this.createdAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  Download copyWithCompanion(DownloadsCompanion data) {
    return Download(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      title: data.title.present ? data.title.value : this.title,
      site: data.site.present ? data.site.value : this.site,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      kind: data.kind.present ? data.kind.value : this.kind,
      quality: data.quality.present ? data.quality.value : this.quality,
      selector: data.selector.present ? data.selector.value : this.selector,
      extraArgs: data.extraArgs.present ? data.extraArgs.value : this.extraArgs,
      parts: data.parts.present ? data.parts.value : this.parts,
      status: data.status.present ? data.status.value : this.status,
      percent: data.percent.present ? data.percent.value : this.percent,
      uri: data.uri.present ? data.uri.value : this.uri,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      mime: data.mime.present ? data.mime.value : this.mime,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      error: data.error.present ? data.error.value : this.error,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Download(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('site: $site, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('durationSec: $durationSec, ')
          ..write('kind: $kind, ')
          ..write('quality: $quality, ')
          ..write('selector: $selector, ')
          ..write('extraArgs: $extraArgs, ')
          ..write('parts: $parts, ')
          ..write('status: $status, ')
          ..write('percent: $percent, ')
          ..write('uri: $uri, ')
          ..write('filePath: $filePath, ')
          ..write('mime: $mime, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    url,
    title,
    site,
    thumbnail,
    durationSec,
    kind,
    quality,
    selector,
    extraArgs,
    parts,
    status,
    percent,
    uri,
    filePath,
    mime,
    sizeBytes,
    error,
    createdAt,
    finishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Download &&
          other.id == this.id &&
          other.url == this.url &&
          other.title == this.title &&
          other.site == this.site &&
          other.thumbnail == this.thumbnail &&
          other.durationSec == this.durationSec &&
          other.kind == this.kind &&
          other.quality == this.quality &&
          other.selector == this.selector &&
          other.extraArgs == this.extraArgs &&
          other.parts == this.parts &&
          other.status == this.status &&
          other.percent == this.percent &&
          other.uri == this.uri &&
          other.filePath == this.filePath &&
          other.mime == this.mime &&
          other.sizeBytes == this.sizeBytes &&
          other.error == this.error &&
          other.createdAt == this.createdAt &&
          other.finishedAt == this.finishedAt);
}

class DownloadsCompanion extends UpdateCompanion<Download> {
  final Value<String> id;
  final Value<String> url;
  final Value<String> title;
  final Value<String> site;
  final Value<String?> thumbnail;
  final Value<int?> durationSec;
  final Value<String> kind;
  final Value<String> quality;
  final Value<String> selector;
  final Value<String> extraArgs;
  final Value<int> parts;
  final Value<String> status;
  final Value<double?> percent;
  final Value<String?> uri;
  final Value<String?> filePath;
  final Value<String?> mime;
  final Value<int?> sizeBytes;
  final Value<String?> error;
  final Value<DateTime> createdAt;
  final Value<DateTime?> finishedAt;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.site = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.kind = const Value.absent(),
    this.quality = const Value.absent(),
    this.selector = const Value.absent(),
    this.extraArgs = const Value.absent(),
    this.parts = const Value.absent(),
    this.status = const Value.absent(),
    this.percent = const Value.absent(),
    this.uri = const Value.absent(),
    this.filePath = const Value.absent(),
    this.mime = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.error = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required String id,
    required String url,
    required String title,
    required String site,
    this.thumbnail = const Value.absent(),
    this.durationSec = const Value.absent(),
    required String kind,
    required String quality,
    required String selector,
    this.extraArgs = const Value.absent(),
    this.parts = const Value.absent(),
    required String status,
    this.percent = const Value.absent(),
    this.uri = const Value.absent(),
    this.filePath = const Value.absent(),
    this.mime = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.error = const Value.absent(),
    required DateTime createdAt,
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       url = Value(url),
       title = Value(title),
       site = Value(site),
       kind = Value(kind),
       quality = Value(quality),
       selector = Value(selector),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<Download> custom({
    Expression<String>? id,
    Expression<String>? url,
    Expression<String>? title,
    Expression<String>? site,
    Expression<String>? thumbnail,
    Expression<int>? durationSec,
    Expression<String>? kind,
    Expression<String>? quality,
    Expression<String>? selector,
    Expression<String>? extraArgs,
    Expression<int>? parts,
    Expression<String>? status,
    Expression<double>? percent,
    Expression<String>? uri,
    Expression<String>? filePath,
    Expression<String>? mime,
    Expression<int>? sizeBytes,
    Expression<String>? error,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (site != null) 'site': site,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (durationSec != null) 'duration_sec': durationSec,
      if (kind != null) 'kind': kind,
      if (quality != null) 'quality': quality,
      if (selector != null) 'selector': selector,
      if (extraArgs != null) 'extra_args': extraArgs,
      if (parts != null) 'parts': parts,
      if (status != null) 'status': status,
      if (percent != null) 'percent': percent,
      if (uri != null) 'uri': uri,
      if (filePath != null) 'file_path': filePath,
      if (mime != null) 'mime': mime,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (error != null) 'error': error,
      if (createdAt != null) 'created_at': createdAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith({
    Value<String>? id,
    Value<String>? url,
    Value<String>? title,
    Value<String>? site,
    Value<String?>? thumbnail,
    Value<int?>? durationSec,
    Value<String>? kind,
    Value<String>? quality,
    Value<String>? selector,
    Value<String>? extraArgs,
    Value<int>? parts,
    Value<String>? status,
    Value<double?>? percent,
    Value<String?>? uri,
    Value<String?>? filePath,
    Value<String?>? mime,
    Value<int?>? sizeBytes,
    Value<String?>? error,
    Value<DateTime>? createdAt,
    Value<DateTime?>? finishedAt,
    Value<int>? rowid,
  }) {
    return DownloadsCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      site: site ?? this.site,
      thumbnail: thumbnail ?? this.thumbnail,
      durationSec: durationSec ?? this.durationSec,
      kind: kind ?? this.kind,
      quality: quality ?? this.quality,
      selector: selector ?? this.selector,
      extraArgs: extraArgs ?? this.extraArgs,
      parts: parts ?? this.parts,
      status: status ?? this.status,
      percent: percent ?? this.percent,
      uri: uri ?? this.uri,
      filePath: filePath ?? this.filePath,
      mime: mime ?? this.mime,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (site.present) {
      map['site'] = Variable<String>(site.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<String>(thumbnail.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (selector.present) {
      map['selector'] = Variable<String>(selector.value);
    }
    if (extraArgs.present) {
      map['extra_args'] = Variable<String>(extraArgs.value);
    }
    if (parts.present) {
      map['parts'] = Variable<int>(parts.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (percent.present) {
      map['percent'] = Variable<double>(percent.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('site: $site, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('durationSec: $durationSec, ')
          ..write('kind: $kind, ')
          ..write('quality: $quality, ')
          ..write('selector: $selector, ')
          ..write('extraArgs: $extraArgs, ')
          ..write('parts: $parts, ')
          ..write('status: $status, ')
          ..write('percent: $percent, ')
          ..write('uri: $uri, ')
          ..write('filePath: $filePath, ')
          ..write('mime: $mime, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('error: $error, ')
          ..write('createdAt: $createdAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [downloads];
}

typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  required String id,
  required String url,
  required String title,
  required String site,
  Value<String?> thumbnail,
  Value<int?> durationSec,
  required String kind,
  required String quality,
  required String selector,
  Value<String> extraArgs,
  Value<int> parts,
  required String status,
  Value<double?> percent,
  Value<String?> uri,
  Value<String?> filePath,
  Value<String?> mime,
  Value<int?> sizeBytes,
  Value<String?> error,
  required DateTime createdAt,
  Value<DateTime?> finishedAt,
  Value<int> rowid,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<String> id,
  Value<String> url,
  Value<String> title,
  Value<String> site,
  Value<String?> thumbnail,
  Value<int?> durationSec,
  Value<String> kind,
  Value<String> quality,
  Value<String> selector,
  Value<String> extraArgs,
  Value<int> parts,
  Value<String> status,
  Value<double?> percent,
  Value<String?> uri,
  Value<String?> filePath,
  Value<String?> mime,
  Value<int?> sizeBytes,
  Value<String?> error,
  Value<DateTime> createdAt,
  Value<DateTime?> finishedAt,
  Value<int> rowid,
});

class $$DownloadsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get site => $composableBuilder(
    column: $table.site,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selector => $composableBuilder(
    column: $table.selector,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extraArgs => $composableBuilder(
    column: $table.extraArgs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parts => $composableBuilder(
    column: $table.parts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get percent => $composableBuilder(
    column: $table.percent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get site => $composableBuilder(
    column: $table.site,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selector => $composableBuilder(
    column: $table.selector,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extraArgs => $composableBuilder(
    column: $table.extraArgs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parts => $composableBuilder(
    column: $table.parts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get percent => $composableBuilder(
    column: $table.percent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get site =>
      $composableBuilder(column: $table.site, builder: (column) => column);

  GeneratedColumn<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<String> get selector =>
      $composableBuilder(column: $table.selector, builder: (column) => column);

  GeneratedColumn<String> get extraArgs =>
      $composableBuilder(column: $table.extraArgs, builder: (column) => column);

  GeneratedColumn<int> get parts =>
      $composableBuilder(column: $table.parts, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get percent =>
      $composableBuilder(column: $table.percent, builder: (column) => column);

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );
}

class $$DownloadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadsTable,
          Download,
          $$DownloadsTableFilterComposer,
          $$DownloadsTableOrderingComposer,
          $$DownloadsTableAnnotationComposer,
          $$DownloadsTableCreateCompanionBuilder,
          $$DownloadsTableUpdateCompanionBuilder,
          (Download, BaseReferences<_$AppDatabase, $DownloadsTable, Download>),
          Download,
          PrefetchHooks Function()
        > {
  $$DownloadsTableTableManager(_$AppDatabase db, $DownloadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> site = const Value.absent(),
                Value<String?> thumbnail = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> quality = const Value.absent(),
                Value<String> selector = const Value.absent(),
                Value<String> extraArgs = const Value.absent(),
                Value<int> parts = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double?> percent = const Value.absent(),
                Value<String?> uri = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String?> mime = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion(
                id: id,
                url: url,
                title: title,
                site: site,
                thumbnail: thumbnail,
                durationSec: durationSec,
                kind: kind,
                quality: quality,
                selector: selector,
                extraArgs: extraArgs,
                parts: parts,
                status: status,
                percent: percent,
                uri: uri,
                filePath: filePath,
                mime: mime,
                sizeBytes: sizeBytes,
                error: error,
                createdAt: createdAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String url,
                required String title,
                required String site,
                Value<String?> thumbnail = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                required String kind,
                required String quality,
                required String selector,
                Value<String> extraArgs = const Value.absent(),
                Value<int> parts = const Value.absent(),
                required String status,
                Value<double?> percent = const Value.absent(),
                Value<String?> uri = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String?> mime = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<String?> error = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion.insert(
                id: id,
                url: url,
                title: title,
                site: site,
                thumbnail: thumbnail,
                durationSec: durationSec,
                kind: kind,
                quality: quality,
                selector: selector,
                extraArgs: extraArgs,
                parts: parts,
                status: status,
                percent: percent,
                uri: uri,
                filePath: filePath,
                mime: mime,
                sizeBytes: sizeBytes,
                error: error,
                createdAt: createdAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadsTable, Download>(table),
                  BaseReferences<_$AppDatabase, $DownloadsTable, Download>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadsTable,
      Download,
      $$DownloadsTableFilterComposer,
      $$DownloadsTableOrderingComposer,
      $$DownloadsTableAnnotationComposer,
      $$DownloadsTableCreateCompanionBuilder,
      $$DownloadsTableUpdateCompanionBuilder,
      (Download, BaseReferences<_$AppDatabase, $DownloadsTable, Download>),
      Download,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
}
