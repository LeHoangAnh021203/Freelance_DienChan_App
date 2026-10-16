part of 'main.dart';

String _formatDateTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(time.day)}/${two(time.month)}/${time.year} ${two(time.hour)}:${two(time.minute)}';
}

const _moodLabels = {
  1: 'Rất mệt',
  2: 'Còn khó chịu',
  3: 'Bình thường',
  4: 'Dễ chịu hơn',
  5: 'Rất tốt',
};

/// Opens the journal editor; returns the saved entry.
Future<JournalEntry?> _showJournalEditor(
  BuildContext context, {
  String initialTitle = '',
  String? relatedType,
  String? relatedId,
}) async {
  JournalEntry? saved;
  await _requireSignIn(context, () async {
    saved = await showModalBottomSheet<JournalEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _JournalEditorSheet(
        initialTitle: initialTitle,
        relatedType: relatedType,
        relatedId: relatedId,
      ),
    );
  });
  if (saved != null) unawaited(_refreshStats());
  return saved;
}

String _bookmarkCollection(String targetType) =>
    targetType == 'protocol' ? 'phác đồ cá nhân' : 'mục yêu thích';

Future<void> _saveBookmark(
  BuildContext context, {
  required String targetType,
  required String targetId,
  required String title,
}) async {
  await _requireSignIn(context, () async {
    try {
      await _api.addBookmark(
        targetType: targetType,
        targetId: targetId,
        title: title,
      );
      unawaited(_refreshStats());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã lưu "$title" vào ${_bookmarkCollection(targetType)}.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) _showApiError(context, error);
    }
  });
}

class _JournalEditorSheet extends StatefulWidget {
  const _JournalEditorSheet({
    required this.initialTitle,
    this.relatedType,
    this.relatedId,
  });

  final String initialTitle;
  final String? relatedType;
  final String? relatedId;

  @override
  State<_JournalEditorSheet> createState() => _JournalEditorSheetState();
}

class _JournalEditorSheetState extends State<_JournalEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(
    text: widget.initialTitle,
  );
  final _noteController = TextEditingController();
  int? _mood;
  bool _busy = false;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final entry = await _api.addJournal(
        title: _titleController.text.trim(),
        note: _noteController.text.trim(),
        mood: _mood,
        relatedType: widget.relatedType,
        relatedId: widget.relatedId,
      );
      if (mounted) Navigator.pop(context, entry);
    } catch (error) {
      if (mounted) _showApiError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ghi nhật ký',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'VD: Day huyệt 26 buổi sáng',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Vui lòng nhập tiêu đề'
                  : null,
            ),
            TextFormField(
              controller: _noteController,
              maxLines: 4,
              maxLength: 4000,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Cảm nhận, thời gian day, thay đổi triệu chứng...',
                border: OutlineInputBorder(),
              ),
            ),
            const Text(
              'Cảm nhận sau khi day',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _moodLabels.entries
                  .map(
                    (entry) => ChoiceChip(
                      label: Text('${entry.key} · ${entry.value}'),
                      selected: _mood == entry.key,
                      onSelected: (selected) =>
                          setState(() => _mood = selected ? entry.key : null),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(_busy ? 'Đang lưu...' : 'Lưu nhật ký'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyDataPage extends StatefulWidget {
  const _MyDataPage();

  @override
  State<_MyDataPage> createState() => _MyDataPageState();
}

class _MyDataPageState extends State<_MyDataPage> {
  late Future<List<JournalEntry>> _journals = _api.journals();
  late Future<List<Bookmark>> _bookmarks = _api.bookmarks();
  late Future<List<CourseRegistration>> _courses = _api.myCourseRegistrations();

  void _reload() {
    setState(() {
      _journals = _api.journals();
      _bookmarks = _api.bookmarks();
      _courses = _api.myCourseRegistrations();
    });
    unawaited(_refreshStats());
  }

  Future<void> _confirmDelete(
    String what,
    Future<void> Function() remove,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa $what?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await remove();
      _reload();
    } catch (error) {
      if (mounted) _showApiError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nhật ký & mục đã lưu'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Nhật ký'),
              Tab(text: 'Đã lưu'),
              Tab(text: 'Khóa học'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            if (await _showJournalEditor(context) != null) _reload();
          },
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Ghi nhật ký'),
        ),
        body: TabBarView(
          children: [
            _AsyncList<JournalEntry>(
              future: _journals,
              onRefresh: _reload,
              empty: 'Chưa có nhật ký. Bấm "Ghi nhật ký" để bắt đầu theo dõi.',
              itemBuilder: (entry) => Card(
                child: ListTile(
                  title: Text(
                    entry.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    [
                      _formatDateTime(entry.createdAt),
                      if (entry.mood != null)
                        'Cảm nhận: ${_moodLabels[entry.mood]}',
                      if (entry.note.isNotEmpty) entry.note,
                    ].join('\n'),
                  ),
                  isThreeLine: entry.note.isNotEmpty || entry.mood != null,
                  trailing: IconButton(
                    tooltip: 'Xóa nhật ký',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(
                      'nhật ký',
                      () => _api.removeJournal(entry.id),
                    ),
                  ),
                ),
              ),
            ),
            _AsyncList<Bookmark>(
              future: _bookmarks,
              onRefresh: _reload,
              empty:
                  'Chưa có mục đã lưu. Mở một huyệt và chọn "Thêm vào yêu thích" '
                  'hoặc "Thêm vào phác đồ cá nhân".',
              itemBuilder: (bookmark) => Card(
                child: ListTile(
                  leading: Icon(
                    bookmark.targetType == 'protocol'
                        ? Icons.assignment_rounded
                        : Icons.bookmark_rounded,
                  ),
                  title: Text(
                    bookmark.title.isEmpty ? bookmark.targetId : bookmark.title,
                  ),
                  subtitle: Text(
                    bookmark.targetType == 'protocol'
                        ? 'Phác đồ cá nhân · ${_formatDateTime(bookmark.createdAt)}'
                        : 'Yêu thích · ${_formatDateTime(bookmark.createdAt)}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Bỏ lưu',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(
                      'mục đã lưu',
                      () => _api.removeBookmark(bookmark.id),
                    ),
                  ),
                ),
              ),
            ),
            _AsyncList<CourseRegistration>(
              future: _courses,
              onRefresh: _reload,
              empty: 'Bạn chưa đăng ký khóa học nào.',
              itemBuilder: (registration) => Card(
                child: ListTile(
                  leading: const Icon(Icons.school_rounded),
                  title: Text(registration.courseName),
                  subtitle: Text(
                    'Gửi lúc ${_formatDateTime(registration.createdAt)}\n'
                    '${registration.status == 'new' ? 'Đang chờ trung tâm liên hệ' : registration.status}',
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AsyncList<T> extends StatelessWidget {
  const _AsyncList({
    required this.future,
    required this.onRefresh,
    required this.empty,
    required this.itemBuilder,
  });

  final Future<List<T>> future;
  final VoidCallback onRefresh;
  final String empty;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onRefresh,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(empty, textAlign: TextAlign.center),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: items.length,
            itemBuilder: (context, index) => itemBuilder(items[index]),
          ),
        );
      },
    );
  }
}
