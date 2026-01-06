import 'package:flutter/material.dart';
import 'package:zad_aldaia/core/routing/routes.dart';

class AddNewCategoryCard extends StatefulWidget {
  const AddNewCategoryCard({super.key});

  @override
  State<AddNewCategoryCard> createState() => _AddNewCategoryCardState();
}

class _AddNewCategoryCardState extends State<AddNewCategoryCard> {
  bool _isHovered = false;
  double _scale = 1.0;
  double _elevation = 6.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        _isHovered = true;
        _scale = 1.05;
        _elevation = 16.0;
      }),
      onExit: (_) => setState(() {
        _isHovered = false;
        _scale = 1.0;
        _elevation = 6.0;
      }),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 200),
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_isHovered ? -0.08 : 0.0)
              ..rotateY(_isHovered ? 0.05 : 0.0),
            alignment: FractionalOffset.center,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade300.withOpacity(0.8),
                    blurRadius: _elevation * 1.5,
                    spreadRadius: _elevation / 3,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                borderRadius: BorderRadius.circular(24),
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      MyRoutes.addCategoryScreen,
                      arguments: {"is_section": true},
                    );
                  },
                  splashColor: Colors.green.withOpacity(0.3),
                  highlightColor: Colors.green.withOpacity(0.1),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isHovered
                                ? [
                                    Colors.green.shade100,
                                    Colors.white,
                                    Colors.green.shade50,
                                  ]
                                : [
                                    Colors.green.shade50,
                                    Colors.white,
                                    Colors.green.shade100,
                                  ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isHovered
                                ? Colors.green.shade800
                                : Colors.green.shade700,
                            width: _isHovered ? 3 : 2,
                          ),
                        ),
                      ),

                      // Content
                      Positioned.fill(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: 48,
                              color: Colors.green.shade800,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Add New',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.white.withOpacity(0.9),
                                        blurRadius: 8,
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}