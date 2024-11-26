import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class InfoCarousel extends StatefulWidget {
  const InfoCarousel({super.key});

  @override
  InfoCarouselState createState() => InfoCarouselState();
}

class InfoCarouselState extends State<InfoCarousel> {
  int _currentIndex = 0;

  final List<String> _imagePaths = [
    'assets/images/camera_panel.jpg',
    'assets/images/home_panel.jpg',
    'assets/images/configurations_panel.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.blue,
          width: double.infinity,
          height: 400,
          child: CarouselSlider(
            options: CarouselOptions(
              autoPlayInterval: const Duration(seconds: 3),
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 3 / 4,
              viewportFraction: 0.95,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            items: _imagePaths
                .map((imagePath) => _buildCarouselItem(imagePath))
                .toList(),
          ),
        ),
        const SizedBox(height: 15),
        _buildPageIndicators(_imagePaths.length),
      ],
    );
  }

  Widget _buildCarouselItem(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildPageIndicators(int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == index ? Colors.black : Colors.grey,
          ),
        );
      }),
    );
  }
}
