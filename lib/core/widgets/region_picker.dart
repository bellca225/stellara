import 'package:flutter/material.dart';

import '../data/kr_regions.dart';
import 'glass.dart';

/// 한국 지역 선택 글라스 바텀시트. 선택한 KrRegion 반환 (취소 시 null).
Future<KrRegion?> showRegionPicker(
  BuildContext context, {
  String? selectedName,
}) {
  return showModalBottomSheet<KrRegion>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _RegionPickerSheet(selectedName: selectedName),
  );
}

class _RegionPickerSheet extends StatelessWidget {
  const _RegionPickerSheet({this.selectedName});

  final String? selectedName;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1E38), Color(0xFF0A1326)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0x1FFFFFFF), width: 0.8),
          boxShadow: kGlassShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '출생지 선택',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                itemCount: kKrRegions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final region = kKrRegions[i];
                  final isSelected = region.name == selectedName;
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(region),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0x4D2B7FFF), Color(0x4D155DFC)],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0x0FFFFFFF), Color(0x08FFFFFF)],
                              ),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0x66FFFFFF)
                              : const Color(0x14FFFFFF),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: isSelected
                                ? const Color(0xFF8EC5FF)
                                : const Color(0x808EC5FF),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              region.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xE6FFFFFF),
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                letterSpacing: -0.2,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Color(0xFF8EC5FF),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
