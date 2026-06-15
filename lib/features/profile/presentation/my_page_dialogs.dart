part of 'my_page_screen.dart';

class _EditNicknameDialog extends StatefulWidget {
  const _EditNicknameDialog({required this.initialValue, required this.onSave});

  final String initialValue;
  final Future<void> Function(String value) onSave;

  @override
  State<_EditNicknameDialog> createState() => _EditNicknameDialogState();
}

class _EditNicknameDialogState extends State<_EditNicknameDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = '닉네임을 입력해주세요.');
      return;
    }
    if (value.length > 20) {
      setState(() => _error = '닉네임은 20자 이내로 입력해주세요.');
      return;
    }
    if (value == widget.initialValue.trim()) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onSave(value);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on _UiMessageException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '닉네임을 저장하지 못했어요. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DialogCard(
      title: '닉네임 수정',
      onClose: _isSaving
          ? null
          : () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop(false);
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel('새 닉네임'),
          const SizedBox(height: 8),
          _GlassFieldShell(
            hasError: _error != null,
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              enabled: !_isSaving,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                color: _C.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.2,
                fontFamily: 'Pretendard',
              ),
              cursorColor: _C.accent,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 14,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(
                color: _C.error,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.33,
                letterSpacing: -0.2,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _GlassPillButton(
                  label: '취소',
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop(false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlassPillButton(
                  label: '저장',
                  filled: true,
                  isLoading: _isSaving,
                  onTap: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditBirthInfoDialog extends StatefulWidget {
  const _EditBirthInfoDialog({
    required this.initialBirthInfo,
    required this.displayName,
    required this.onSave,
  });

  final BirthInfo? initialBirthInfo;
  final String displayName;
  final Future<void> Function(BirthInfo birthInfo) onSave;

  @override
  State<_EditBirthInfoDialog> createState() => _EditBirthInfoDialogState();
}

class _EditBirthInfoDialogState extends State<_EditBirthInfoDialog> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  KrRegion? _selectedRegion;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final birth = widget.initialBirthInfo;
    if (birth != null) {
      _selectedDate = DateTime(
        birth.dateTime.year,
        birth.dateTime.month,
        birth.dateTime.day,
      );
      _selectedTime = TimeOfDay(
        hour: birth.dateTime.hour,
        minute: birth.dateTime.minute,
      );
    }
    _selectedRegion = findKrRegionByName(birth?.placeName);
  }

  Future<void> _pickRegion() async {
    FocusScope.of(context).unfocus();
    final picked = await showRegionPicker(
      context,
      selectedName: _selectedRegion?.name,
    );
    if (picked != null) {
      setState(() {
        _selectedRegion = picked;
        _error = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showGlassDatePicker(
      context,
      initialDate: _selectedDate ?? DateTime(2002, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _error = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showGlassTimePicker(
      context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      setState(() => _error = '생년월일을 선택해주세요.');
      return;
    }
    if (_selectedTime == null) {
      setState(() => _error = '출생 시간을 선택해주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final dt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final region = _selectedRegion;
      if (region == null) {
        throw const _UiMessageException('출생지를 선택해주세요.');
      }
      final double latitude = region.latitude;
      final double longitude = region.longitude;
      final String placeName = region.name;

      final birthInfo = BirthInfo(
        nickname: widget.displayName,
        dateTime: dt,
        latitude: latitude,
        longitude: longitude,
        utcOffset: widget.initialBirthInfo?.utcOffset ?? '+09:00',
        placeName: placeName,
      );

      final initial = widget.initialBirthInfo;
      final isSameAsInitial =
          initial != null &&
          initial.dateTime == birthInfo.dateTime &&
          initial.latitude == birthInfo.latitude &&
          initial.longitude == birthInfo.longitude &&
          initial.utcOffset == birthInfo.utcOffset &&
          (initial.placeName ?? '') == (birthInfo.placeName ?? '') &&
          initial.nickname == birthInfo.nickname;
      if (isSameAsInitial) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(false);
        return;
      }

      await widget.onSave(birthInfo);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on _UiMessageException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '출생 정보를 저장하지 못했어요. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _dateText() {
    final date = _selectedDate;
    if (date == null) {
      return '';
    }
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
  }

  String _timeText() {
    final time = _selectedTime;
    if (time == null) {
      return '';
    }
    return '${_pad(time.hour)}:${_pad(time.minute)}';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return _DialogCard(
      title: '출생 정보 수정',
      onClose: _isSaving
          ? null
          : () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop(false);
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel('생년월일'),
          const SizedBox(height: 8),
          _DisplayInput(
            value: _dateText(),
            placeholder: '생년월일을 선택해주세요',
            onTap: _pickDate,
            hasError: _error == '생년월일을 선택해주세요.',
          ),
          const SizedBox(height: 20),
          const _FieldLabel('출생 시간'),
          const SizedBox(height: 8),
          _DisplayInput(
            value: _timeText(),
            placeholder: '출생 시간을 선택해주세요',
            onTap: _pickTime,
            hasError: _error == '출생 시간을 선택해주세요.',
          ),
          const SizedBox(height: 20),
          const _FieldLabel('출생지'),
          const SizedBox(height: 8),
          _DisplayInput(
            value: _selectedRegion?.name,
            placeholder: '출생지를 선택해주세요',
            onTap: _isSaving ? () {} : _pickRegion,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                color: _C.error,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.33,
                letterSpacing: -0.2,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _GlassPillButton(
                  label: '취소',
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop(false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlassPillButton(
                  label: '저장',
                  filled: true,
                  isLoading: _isSaving,
                  onTap: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
