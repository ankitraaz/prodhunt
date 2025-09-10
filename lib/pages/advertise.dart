import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdvertisePage extends StatelessWidget {
  const AdvertisePage({super.key});

  // function to open website
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final partners = [
      {
        "name": "Netlify",
        "logo": "assets/images/partner1.jpeg",
        "url": "https://www.netlify.com",
      },
      {
        "name": "Vercel",
        "logo": "assets/images/partner2.jpeg",
        "url": "https://vercel.com",
      },
      {
        "name": "Notion",
        "logo": "assets/images/notion.jpeg",
        "url": "https://www.notion.so",
      },
      {
        "name": "LinkedIn",
        "logo": "assets/images/linkedin.png",
        "url": "https://www.linkedin.com",
      },
    ];

    return Scaffold(
      backgroundColor: cs.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),

            // Section Title
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Column(
                children: [
                  Text(
                    "OUR PARTNERS",
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We work with the best partners",
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Partner Logos Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: partners.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.5,
                ),
                itemBuilder: (context, index) {
                  final partner = partners[index];
                  return InkWell(
                    onTap: () => _launchURL(partner["url"]!),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: cs.shadow.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Center(
                        child: Image.asset(
                          partner["logo"]!,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint(
                              'Error loading image: ${partner["logo"]} - $error',
                            );
                            return Icon(Icons.error, color: cs.error);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
