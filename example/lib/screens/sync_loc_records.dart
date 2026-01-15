import 'package:flutter/material.dart';
import 'package:wise_apartment/wise_apartment.dart';
import 'package:flutter/services.dart';
import 'package:wise_apartment/src/wise_status_store.dart';

class SyncLocRecordsScreen extends StatefulWidget {
  final Map<String, dynamic> auth;

  const SyncLocRecordsScreen({Key? key, required this.auth}) : super(key: key);

  @override
  State<SyncLocRecordsScreen> createState() => _SyncLocRecordsScreenState();
}

class _SyncLocRecordsScreenState extends State<SyncLocRecordsScreen> {
  final _plugin = WiseApartment();
  final List<HXRecordBaseModel> _records = [];
  int _currentPage = 1; // 1-based
  bool _loading = false;
  final int _pageSize = 10; // show 10 per page
  int _total = 0;
  int get _totalPages =>
      _total == 0 ? 1 : ((_total + _pageSize - 1) ~/ _pageSize);

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  Future<void> _loadPage(int page) async {
    if (_loading) return;
    setState(() {
      _loading = true;
    });
    final startNum = (page - 1) * _pageSize;
    try {
      final res = await _plugin.syncLockRecordsPage(
        widget.auth,
        startNum,
        _pageSize,
      );
      // store last numeric code if present (returns a status object)
      WiseStatusHandler? status;
      try {
        status = WiseStatusStore.setFromMap(res as Map<String, dynamic>?);
      } catch (_) {}
      final List<dynamic> recs = res['records'] ?? [];
      final int total = res['total'] ?? 0;

      // Convert platform Maps -> LockRecord -> HXRecordBaseModel using
      // existing project factories/extensions so the example UI shows
      // typed models consistent with the library's domain types.
      final locks = LockRecord.listFromDynamic(recs);
      final typed = locks
          .map((l) => hxRecordFromLockRecord(l))
          .toList(growable: false);

      setState(() {
        _records
          ..clear()
          ..addAll(typed);
        _total = total;
        _currentPage = page;
      });
    } catch (e) {
      WiseStatusHandler? status;
      String? codeStr;
      String? msg;
      if (e is WiseApartmentException) {
        codeStr = e.code;
        msg = e.message;
        try {
          status = WiseStatusStore.setFromWiseException(e);
        } catch (_) {}
      } else if (e is PlatformException) {
        try {
          status = WiseStatusStore.setFromMap(
            e.details as Map<String, dynamic>?,
          );
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sync error: ${msg ?? e} (code: ${codeStr ?? status?.code})',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadPage(_currentPage);
  }

  Widget _buildRecordTile(HXRecordBaseModel r) {
    final map = r.toMap();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.modelType.isNotEmpty ? r.modelType : r.typeName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...map.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text('${e.key}: ${e.value}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // `_prettyRecord` removed — not referenced in the UI.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Loc records'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Total records on lock: $_total'),
            ),
          Expanded(
            child: _records.isEmpty && _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _records.length,
                    itemBuilder: (context, index) =>
                        _buildRecordTile(_records[index]),
                  ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          // Page selector
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(_totalPages, (i) {
                  final pageNum = i + 1;
                  final selected = pageNum == _currentPage;
                  return OutlinedButton(
                    onPressed: selected ? null : () => _loadPage(pageNum),
                    style: selected
                        ? OutlinedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.12),
                          )
                        : null,
                    child: Text(
                      pageNum.toString(),
                      style: TextStyle(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
