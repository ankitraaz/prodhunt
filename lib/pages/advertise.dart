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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),

            // Section Title
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Column(
                children: const [
                  Text(
                    "OUR PARTNERS",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "We work with the best partners",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Center(
                        child: Image.asset(
                          partner["logo"]!,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            print(
                              'Error loading image: ${partner["logo"]} - $error',
                            );
                            return const Icon(Icons.error);
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
