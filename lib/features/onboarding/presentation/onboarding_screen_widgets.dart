part of 'onboarding_screen.dart';

// ── 스텝 카드 ────────────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.nameCtrl,
    this.nameError,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedRegion,
    required this.error,
    required this.onPickDate,
    required this.onPickTime,
    required this.onPickRegion,
  });

  final int step;
  final TextEditingController nameCtrl;
  final String? nameError;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final KrRegion? selectedRegion;
  final String? error;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onPickRegion;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 28 / 20,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8EC5FF),
              fontSize: 12,
              height: 16 / 12,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 20),
          if (step == 0) ...[
            const _GlassFieldLabel('이름'),
            const SizedBox(height: 8),
            _GlassTextInput(
              controller: nameCtrl,
              hintText: '',
              autofocus: true,
              maxLength: 20,
              errorText: nameError,
            ),
          ],
          if (step == 1) ...[
            const _GlassFieldLabel('생년월일'),
            const SizedBox(height: 8),
            _GlassPickerButton(
              icon: Icons.calendar_today_outlined,
              label: selectedDate == null
                  ? '날짜 선택'
                  : '${selectedDate!.year}년 ${selectedDate!.month}월 ${selectedDate!.day}일',
              selected: selectedDate != null,
              onTap: onPickDate,
            ),
          ],
          if (step == 2) ...[
            const _GlassFieldLabel('출생 시간'),
            const SizedBox(height: 8),
            _GlassPickerButton(
              icon: Icons.access_time_outlined,
              label: selectedTime == null
                  ? '시간 선택'
                  : selectedTime!.format(context),
              selected: selectedTime != null,
              onTap: onPickTime,
            ),
          ],
          if (step == 3) ...[
            const _GlassFieldLabel('출생지'),
            const SizedBox(height: 8),
            _GlassPickerButton(
              icon: Icons.location_on_outlined,
              label: selectedRegion?.name ?? '출생지 선택',
              selected: selectedRegion != null,
              onTap: onPickRegion,
            ),
            const SizedBox(height: 8),
            const Text(
              '목록에서 가장 가까운 지역을 선택해주세요.',
              style: TextStyle(color: Color(0x668EC5FF), fontSize: 12),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 12,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _title {
    switch (step) {
      case 0:
        return '어떻게 불러드리면 될까요?';
      case 1:
        return '언제 태어나셨나요?';
      case 2:
        return '몇 시에 태어나셨나요?';
      default:
        return '어디서 태어나셨나요?';
    }
  }

  String get _subtitle {
    switch (step) {
      case 0:
        return '당신만의 별자리 차트를 만들기 위해 필요해요.';
      case 1:
        return '정확한 별자리 차트를 위해 필요합니다';
      case 2:
        return '정확한 시간은 상승 별자리에 영향을 줍니다';
      default:
        return '지역에 따라 천체의 위치가 달라집니다';
    }
  }
}

class _GlassTextInput extends StatelessWidget {
  const _GlassTextInput({
    required this.controller,
    required this.hintText,
    this.autofocus = false,
    this.maxLength,
    this.errorText,
  });

  final TextEditingController controller;
  final String hintText;
  final bool autofocus;
  final int? maxLength;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return GlassField(
      hasError: errorText != null,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLength: maxLength,
        autocorrect: false,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          letterSpacing: -0.2,
        ),
        cursorColor: const Color(0xFF8EC5FF),
        decoration: InputDecoration(
          hintText: hintText.isEmpty ? null : hintText,
          hintStyle: const TextStyle(
            color: Color(0x808EC5FF),
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.2,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          isDense: true,
          filled: false,
        ),
      ),
    );
  }
}

class _GlassPickerButton extends StatelessWidget {
  const _GlassPickerButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 49,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF51A2FF) : const Color(0x1FFFFFFF),
            width: selected ? 1.5 : 0.612,
          ),
          boxShadow: kGlassShadow,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF8EC5FF)
                  : const Color(0x668EC5FF),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0x80FFFFFF),
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0x40FFFFFF),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassFieldLabel extends StatelessWidget {
  const _GlassFieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFBEDBFF),
        fontSize: 14,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _StepButtons extends StatelessWidget {
  const _StepButtons({
    required this.step,
    required this.isSubmitting,
    required this.onNext,
    required this.onPrev,
  });

  final int step;
  final bool isSubmitting;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      return _GlassPrimaryButton(
        label: '다음',
        isLoading: isSubmitting,
        onTap: onNext,
      );
    }

    return Row(
      children: [
        Expanded(
          child: _GlassSecondaryButton(
            label: '이전',
            isLoading: false,
            onTap: onPrev,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GlassPrimaryButton(
            label: step == 3 ? '완료' : '다음',
            isLoading: isSubmitting,
            onTap: onNext,
          ),
        ),
      ],
    );
  }
}

class _GlassPrimaryButton extends StatelessWidget {
  const _GlassPrimaryButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      label: label,
      isPrimary: true,
      isLoading: isLoading,
      onTap: onTap,
      height: 61,
    );
  }
}

class _GlassSecondaryButton extends StatelessWidget {
  const _GlassSecondaryButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      label: label,
      isPrimary: false,
      isLoading: isLoading,
      onTap: onTap,
      height: 61,
    );
  }
}
