-- Seed products with UI metadata and luxury images
INSERT INTO public.products (name, description, retail_price, image_url, badge, is_active)
VALUES 
('Luminous Glow Serum', 'A concentrated blend of vitamin C and hyaluronic acid for instant radiance and deep hydration.', 45000, '/products/serum.png', 'Best Seller', true),
('Velvet Hydration Cream', 'Rich, nourishing moisturizer that restores the skin barrier and provides 24-hour hydration.', 65000, '/products/cream.png', 'New Arrival', true),
('Pure Clarity Cleanser', 'Gentle foaming cleanser that removes impurities without stripping essential moisture.', 32000, '/products/cleanser.png', NULL, true),
('Silk Shield Sunscreen', 'Invisible, lightweight SPF 50+ protection with a silky finish and broad-spectrum coverage.', 28000, '/products/sunscreen.png', 'Must Have', true),
('Midnight Repair Oil', 'Overnight treatment with botanical extracts to rejuvenate and smooth fine lines.', 78000, '/products/serum.png', 'Limited', true),
('Ocean Mist Toner', 'Refreshing mineral-rich toner that balances pH and preps skin for optimal absorption.', 24000, '/products/cleanser.png', NULL, true),
('Rose Quartz Face Mask', 'Soothing clay mask that detoxifies and brightens tired skin.', 42000, '/products/cream.png', 'Staff Pick', true),
('Gold Eye Elixir', 'Targeted treatment to reduce puffiness and dark circles with pure gold particles.', 95000, '/products/serum.png', 'Premium', true);

-- Seed wholesale prices for these products
INSERT INTO public.product_wholesale_prices (product_id, wholesale_price)
SELECT id, retail_price * 0.6 FROM public.products;
