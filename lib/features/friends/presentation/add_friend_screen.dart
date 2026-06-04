// lib/features/friends/presentation/add_friend_screen.dart
//
// 친구 추가 화면 — Figma 친구관리3/4 구조 기준
//
// 친구관리3: 친구 코드 입력창 + 내 친구 코드 카드 (검색 전)
// 친구관리4: 친구 코드 입력 + 검색 결과 카드(요청하기) + 내 친구 코드 카드
// "친구 추가 요청" 버튼에서 진입. 기존 코드 검색 로직 이전.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/input/app_input_formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../users/application/user_providers.dart';
import '../application/friend_providers.dart';
import '../data/friend_repository.dart';

// ── 공통 글래스 스타일 ─────────────────────────────────────────────
const _glassBoxShadow = [
  BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x801E3A8A), blurRadius: 20, offset: Offset(0, 5)),
];

BoxDecoration _glassCardDecoration({double radius = 24}) => BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
  ),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0x1FFFFFFF), width: 0.636),
  boxShadow: _glassBoxShadow,
);

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

    return StarBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 헤더 ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    _RoundBackButton(
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '친구 관리',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // ── 스크롤 영역 ───────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  children: [
                    // ── 안내 카드 ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: _glassCardDecoration(radius: 16),
                      child: const Text(
                        '친구의 코드를 입력하여 친구 요청을 보낼 수 있습니다.\n친구가 수락하면 함께 궁합을 볼 수 있습니다.',
                        style: TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: 14,
                          height: 1.43,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── 친구 코드 입력 ─────────────────────────
                    const Text(
                      '친구 코드',
                      style: TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _CodeInputField(
                            controller: _codeCtrl,
                            errorText: _error,
                            onSubmitted: (_) => _search(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SearchButton(
                          isLoading: _isSearching,
                          onTap: _isSearching ? null : _search,
                        ),
                      ],
                    ),

                    // ── 검색 결과 ──────────────────────────────
                    if (_searchResult != null) ...[
                      const SizedBox(height: 20),
                      _SearchResultCard(
                        searchResult: _searchResult!,
                        isSending: _isSending,
                        onSend: () => _sendRequest(
                          _searchResult!['uid'] as String? ?? '',
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── 내 친구 코드 ───────────────────────────
                    _MyCodeCard(
                      myCode: myCode,
                      isIssuingCode: _isIssuingCode,
                      onCopy: () => _copyMyCode(myCode),
                      onIssue: _issueMyCode,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 코드 입력 필드 ─────────────────────────────────────────────────
class _CodeInputField extends StatelessWidget {
  const _CodeInputField({
    required this.controller,
    this.errorText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 49,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFFF6B6B)
                  : const Color(0x1FFFFFFF),
              width: 0.636,
            ),
            boxShadow: _glassBoxShadow,
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.visiblePassword,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 6,
            inputFormatters: [FriendCodeTextFormatter()],
            onSubmitted: onSubmitted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: -0.2,
              height: 1.0,
            ),
            cursorColor: const Color(0xFF8EC5FF),
            decoration: const InputDecoration(
              hintText: '영문 대문자/숫자 6자리',
              hintStyle: TextStyle(
                color: Color(0x4DFFFFFF),
                fontSize: 16,
                letterSpacing: -0.2,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              counterText: '',
              isDense: true,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

// ── 검색 버튼 ──────────────────────────────────────────────────────
class _SearchButton extends StatelessWidget {
  const _SearchButton({this.isLoading = false, this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0x1AFFFFFF),
            width: 0.636,
          ),
          boxShadow: _glassBoxShadow,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 16,
                ),
        ),
      ),
    );
  }
}

// ── 검색 결과 카드 ─────────────────────────────────────────────────
class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.searchResult,
    required this.isSending,
    required this.onSend,
  });

  final Map<String, dynamic> searchResult;
  final bool isSending;
  final VoidCallback onSend;

  String get _displayName =>
      searchResult['displayName'] as String? ??
      searchResult['nickname'] as String? ??
      '?';

  String get _initial =>
      _displayName.isNotEmpty ? _displayName[0] : '?';

  String get _sunSign => searchResult['sunSign'] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: _glassCardDecoration(radius: 24),
      child: Row(
        children: [
          // 아바타
          _InitialAvatar(initial: _initial),
          const SizedBox(width: 12),
          // 이름 + 별자리
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                if (_sunSign.isNotEmpty && _sunSign != '-')
                  Text(
                    _sunSign,
                    style: const TextStyle(
                      color: Color(0xFF8EC5FF),
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
              ],
            ),
          ),
          // 요청하기 버튼
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0x662B7FFF), Color(0x40155DFC)],
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0x26FFFFFF),
                  width: 0.636,
                ),
                boxShadow: _glassBoxShadow,
              ),
              child: isSending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '요청하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 내 친구 코드 카드 ──────────────────────────────────────────────
class _MyCodeCard extends StatelessWidget {
  const _MyCodeCard({
    required this.myCode,
    required this.isIssuingCode,
    required this.onCopy,
    required this.onIssue,
  });

  final String myCode;
  final bool isIssuingCode;
  final VoidCallback onCopy;
  final VoidCallback onIssue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x1FFFFFFF), width: 0.636),
        boxShadow: _glassBoxShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
              // 코드 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '내 친구 코드',
                      style: TextStyle(
                        color: Color(0xFF8EC5FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (myCode.isNotEmpty)
                      Text(
                        myCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.4,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: isIssuingCode ? null : onIssue,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0x4D2B7FFF), Color(0x4D155DFC)],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0x26FFFFFF),
                              width: 0.636,
                            ),
                          ),
                          child: isIssuingCode
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  '코드 만들기',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      myCode.isNotEmpty
                          ? '친구에게 이 코드를 공유하세요'
                          : '친구 추가용 코드를 먼저 생성해주세요',
                      style: const TextStyle(
                        color: Color(0xB38EC5FF),
                        fontSize: 12,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // 복사 버튼
              if (myCode.isNotEmpty)
                GestureDetector(
                  onTap: onCopy,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0x26FFFFFF),
                        width: 0.636,
                      ),
                      boxShadow: _glassBoxShadow,
                    ),
                    child: const Icon(
                      Icons.copy_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
    );
  }
}

// ── 아바타 ─────────────────────────────────────────────────────────
class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF51A2FF), Color(0xFF155DFC)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D3B82F6),
            blurRadius: 7.5,
          ),
        ],
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

// ── 뒤로가기 버튼 ──────────────────────────────────────────────────
class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 37,
        height: 37,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0x26FFFFFF),
            width: 0.636,
          ),
          boxShadow: _glassBoxShadow,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}
