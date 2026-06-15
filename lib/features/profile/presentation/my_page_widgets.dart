part of 'my_page_screen.dart';

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.signLabel,
    required this.initial,
    required this.onEdit,
  });

  final String displayName;
  final String signLabel;
  final String initial;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 24,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x402B7FFF), Color(0x00000000)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 24,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_C.avatarStart, _C.avatarEnd],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D3B82F6),
                    blurRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x1AFFFFFF), Color(0x00000000)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: _C.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    letterSpacing: -0.2,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _C.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          height: 1.33,
                          letterSpacing: -0.2,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GlassIconButton(
                      size: 33.256,
                      radius: 28,
                      tooltip: '닉네임 수정',
                      onTap: onEdit,
                      child: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CustomPaint(painter: _EditHeaderIconPainter()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  signLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _C.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    letterSpacing: -0.2,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.cardBorder, width: 0.612),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
        ),
        boxShadow: _glassBoxShadow,
      ),
      child: child,
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.onTap,
    required this.child,
    required this.tooltip,
    this.size = 45.26,
    this.radius = 16,
  });

  final VoidCallback onTap;
  final Widget child;
  final String tooltip;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: _C.pillBorder, width: 0.636),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
            ),
            boxShadow: _glassBoxShadow,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _GlassPillAction extends StatelessWidget {
  const _GlassPillAction({
    required this.label,
    required this.onTap,
    this.leading,
    this.labelColor = _C.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
  });

  final String label;
  final VoidCallback onTap;
  final Widget? leading;
  final Color labelColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: _C.pillBorder, width: 0.636),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
          ),
          boxShadow: _glassBoxShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 5)],
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.43,
                letterSpacing: -0.2,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPillButton extends StatelessWidget {
  const _GlassPillButton({
    required this.label,
    required this.onTap,
    this.leading,
    this.filled = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? leading;
  final bool filled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      label: label,
      isPrimary: filled,
      isLoading: isLoading,
      leading: leading,
      onTap: onTap,
      height: 62,
      fontWeight: FontWeight.w600,
    );
  }
}

class _BirthRow extends StatelessWidget {
  const _BirthRow({
    required this.iconPainter,
    required this.label,
    required this.value,
  });

  final CustomPainter iconPainter;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CustomPaint(painter: iconPainter),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: _C.accent,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.43,
            letterSpacing: -0.2,
            fontFamily: 'Pretendard',
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xE6FFFFFF),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: -0.2,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogCard extends StatelessWidget {
  const _DialogCard({
    required this.title,
    required this.child,
    required this.onClose,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 345),
      child: _GlassSurface(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _C.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: -0.2,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                _GlassIconButton(
                  size: 38,
                  radius: 9999,
                  tooltip: '닫기',
                  onTap: onClose ?? () {},
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFBEDBFF),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: -0.2,
        fontFamily: 'Pretendard',
      ),
    );
  }
}

class _GlassFieldShell extends StatelessWidget {
  const _GlassFieldShell({required this.child, this.hasError = false});

  final Widget child;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? _C.error : _C.cardBorder;
    return Container(
      height: 49,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.636),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
        ),
        boxShadow: _glassBoxShadow,
      ),
      child: child,
    );
  }
}

class _DisplayInput extends StatelessWidget {
  const _DisplayInput({
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.hasError = false,
  });

  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim() ?? '';
    final showPlaceholder = text.isEmpty;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: _GlassFieldShell(
        hasError: hasError,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          child: Text(
            showPlaceholder ? placeholder : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: showPlaceholder ? _C.inputHint : _C.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: -0.2,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ),
    );
  }
}
