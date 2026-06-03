// lib/features/friends/presentation/add_friend_screen.dart
//
// 친구 추가 화면 — Figma 친구관리3/4 구조 기준
//
// 친구관리3/4: 코드 입력 + 검색 결과 + 내 친구 코드 표시
// "친구 추가 요청" 버튼에서 진입. 기존 코드 검색 로직 이전.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/input/app_input_formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../../users/application/user_providers.dart';
import '../application/friend_providers.dart';
import '../data/friend_repository.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _codeCtrl = TextEditingController();

  bool _isSearching = false;
  bool _isSending = false;
  bool _isIssuingCode = false;
  Map<String, dynamic>? _searchResult;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // ── 코드 검색 ──────────────────────────────────────────────────
  Future<void> _search() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    if (code.length != 6) {
      setState(() {
        _searchResult = null;
        _error = '친구 코드는 영문 대문자/숫자 6자리예요.';
      });
      return;
    }

    final myUid = ref.read(currentUserIdProvider).valueOrNull;

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _error = null;
    });

    try {
      final result = await ref
          .read(friendRepositoryProvider)
          .findUserByCode(code);
      if (!mounted) return;

      if (result == null) {
        setState(() => _error = '해당 코드의 사용자를 찾을 수 없어요.');
        return;
      }
      if (result['uid'] == myUid) {
        setState(() => _error = '자기 자신은 추가할 수 없어요.');
        return;
      }
      setState(() => _searchResult = result);
    } catch (_) {
      if (mounted) setState(() => _error = '검색 중 오류가 발생했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ── 친구 요청 전송 ──────────────────────────────────────────────
  Future<void> _sendRequest(String toUid) async {
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final uid = profile?.uid ?? ref.read(currentUserIdProvider).valueOrNull;
    if (uid == null) return;

    setState(() => _isSending = true);
    try {
      await ref
          .read(friendRepositoryProvider)
          .sendRequest(
            fromUid: uid,
            fromNickname: profile?.effectiveDisplayName ?? '',
            fromSunSign: profile?.sunSign ?? '-',
            toUid: toUid,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('친구 요청을 보냈어요!')));
      setState(() {
        _searchResult = null;
        _codeCtrl.clear();
      });
      // 보낸 요청 목록 갱신
      ref.invalidate(sentRequestsProvider);
    } on FriendError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('요청 전송에 실패했어요. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _copyMyCode(String code) async {
    if (code.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('복사할 친구 코드가 아직 없어요.')));
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('내 친구 코드가 복사되었습니다.')));
  }

  Future<void> _issueMyCode() async {
    final uid = ref.read(currentUserIdProvider).valueOrNull;
    if (uid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 정보를 확인할 수 없어요.')));
      return;
    }

    setState(() => _isIssuingCode = true);
    try {
      final code = await ref.read(friendCodeRepositoryProvider).issue(uid);
      ref.invalidate(currentUserProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('친구 코드가 생성되었습니다: $code')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구 코드 생성에 실패했어요. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _isIssuingCode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final myCode = profile?.friendCode ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('친구 관리'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 안내 텍스트 ─────────────────────────────────────────
          Panel(
            child: const Text(
              '친구의 코드를 입력하여 친구 요청을 보낼 수 있습니다.\n'
              '친구가 수락하면 함께 궁합을 볼 수 있습니다.',
              style: TextStyle(color: AppColors.inkMuted, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),

          // ── 친구 코드 입력 ──────────────────────────────────────
          const Text(
            '친구 코드',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.visiblePassword,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  enableSuggestions: false,
                  maxLength: 6,
                  inputFormatters: [FriendCodeTextFormatter()],
                  decoration: InputDecoration(
                    hintText: '영문 대문자/숫자 6자리',
                    counterText: '',
                    errorText: _error,
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSearching ? null : _search,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search_rounded),
                ),
              ),
            ],
          ),

          // ── 검색 결과 ────────────────────────────────────────────
          if (_searchResult != null) ...[
            const SizedBox(height: 16),
            Panel(
              child: Row(
                children: [
                  _Avatar(
                    initial:
                        (_searchResult!['displayName'] as String? ??
                                _searchResult!['nickname'] as String? ??
                                '?')
                            .isNotEmpty
                        ? (_searchResult!['displayName'] as String? ??
                              _searchResult!['nickname'] as String? ??
                              '?')[0]
                        : '?',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _searchResult!['displayName'] as String? ??
                              _searchResult!['nickname'] as String? ??
                              '?',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (_searchResult!['sunSign'] != null)
                          Text(
                            _searchResult!['sunSign'] as String,
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: _isSending
                          ? null
                          : () => _sendRequest(
                              _searchResult!['uid'] as String? ?? '',
                            ),
                      child: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('요청'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          // ── 내 친구 코드 카드 ─────────────────────────────────────
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '내 친구 코드',
                        style: TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (myCode.isNotEmpty)
                      IconButton(
                        tooltip: '복사',
                        onPressed: () => _copyMyCode(myCode),
                        icon: const Icon(
                          Icons.copy_all_outlined,
                          color: AppColors.primaryLight,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (myCode.isNotEmpty)
                  Text(
                    myCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isIssuingCode ? null : _issueMyCode,
                      child: _isIssuingCode
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('내 친구 코드 만들기'),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  myCode.isNotEmpty
                      ? '이 코드를 친구에게 공유하세요'
                      : '친구 추가용 코드를 먼저 생성해주세요',
                  style: TextStyle(color: AppColors.inkSubtle, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.canvas,
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: Text(
        initial,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}
