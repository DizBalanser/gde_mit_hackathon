import Foundation
import SwiftData

struct MockDataGenerator {

    static func generate(in context: ModelContext) {
        let now = Date()
        let cal = Calendar.current

        func date(daysAgo: Int, hour: Int, minute: Int = 0) -> Date {
            let startOfDay = cal.startOfDay(for: now)
            let dayOffset = cal.date(byAdding: .day, value: -daysAgo, to: startOfDay) ?? startOfDay
            return cal.date(bySettingHour: hour, minute: minute, second: 0, of: dayOffset) ?? dayOffset
        }

        var entries: [HealthEntry] = []

        // MARK: - Day -13

        entries.append(HealthEntry(
            date: date(daysAgo: 13, hour: 8),
            rawText: "Oatmeal with berries and honey, black coffee",
            entryType: .food,
            calories: 320, protein: 8, carbs: 58, fat: 6,
            aiSummary: "Nutritious breakfast with antioxidants",
            aiInsight: "Good fiber start, moderate caffeine",
            aiSuggestion: "Consider adding protein source like eggs",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 13, hour: 9),
            rawText: "Went for a morning jog, feeling great and energized!",
            entryType: .mood,
            moodScore: 0.7,
            aiSummary: "Positive mood after morning exercise",
            aiInsight: "Exercise correlates with elevated mood",
            aiSuggestion: "Maintain morning exercise routine",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 13, hour: 13),
            rawText: "Grilled chicken salad with avocado",
            entryType: .food,
            calories: 480, protein: 38, carbs: 22, fat: 24,
            aiSummary: "Balanced high-protein lunch",
            aiInsight: "Excellent protein and healthy fat balance",
            aiSuggestion: "Great meal choice, keep it up",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 13, hour: 19),
            rawText: "Pasta with marinara sauce, garlic bread, soda",
            entryType: .food,
            calories: 720, protein: 18, carbs: 95, fat: 22,
            aiSummary: "High-carb dinner with added sugar",
            aiInsight: "Large evening carb load may affect sleep quality",
            aiSuggestion: "Consider swapping soda for sparkling water",
            isProcessing: false
        ))

        // MARK: - Day -12

        entries.append(HealthEntry(
            date: date(daysAgo: 12, hour: 8),
            rawText: "Bagel with cream cheese, large coffee, energy drink",
            entryType: .food,
            calories: 480, protein: 12, carbs: 62, fat: 18,
            aiSummary: "High-caffeine, high-carb morning",
            aiInsight: "Combined caffeine from coffee and energy drink is excessive",
            aiSuggestion: "Choose one caffeine source to avoid overload",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 12, hour: 12),
            rawText: "McDonald's Big Mac meal with fries and Coke",
            entryType: .food,
            calories: 1050, protein: 32, carbs: 118, fat: 48,
            aiSummary: "High-calorie fast food meal",
            aiInsight: "Excessive sodium and saturated fat in one meal",
            aiSuggestion: "Limit fast food to once per week",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 12, hour: 19),
            rawText: "Pepperoni pizza, 3 slices",
            entryType: .food,
            calories: 760, protein: 31, carbs: 82, fat: 32,
            aiSummary: "High-fat dinner after heavy lunch",
            aiInsight: "Second high-fat meal compounds cardiovascular stress",
            aiSuggestion: "Balance tomorrow with lighter, vegetable-rich meals",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 12, hour: 21),
            rawText: "Feeling sluggish and bloated after eating all day, stressed about work deadlines",
            entryType: .mood,
            moodScore: -0.3,
            aiSummary: "Low mood, digestive discomfort and stress",
            aiInsight: "Poor diet choices correlate with negative emotional state",
            aiSuggestion: "Tomorrow focus on lighter foods and a short walk",
            isProcessing: false
        ))

        // MARK: - Day -11

        entries.append(HealthEntry(
            date: date(daysAgo: 11, hour: 7),
            rawText: "Woke up with a pounding headache, started around 6am",
            entryType: .symptom,
            symptomSeverity: 7,
            symptomName: "Headache",
            aiSummary: "Moderate-severe morning headache",
            aiInsight: "May correlate with yesterday's high caffeine intake",
            aiSuggestion: "Reduce caffeine gradually, stay hydrated",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 11, hour: 10),
            rawText: "Stomach pain and nausea since last night",
            entryType: .symptom,
            symptomSeverity: 5,
            symptomName: "Stomach Pain",
            aiSummary: "Stomach discomfort after fast food",
            aiInsight: "Digestive system reacting to processed food",
            aiSuggestion: "Eat light today, drink ginger tea",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 11, hour: 13),
            rawText: "Plain rice and boiled chicken, water",
            entryType: .food,
            calories: 340, protein: 28, carbs: 45, fat: 4,
            aiSummary: "Recovery meal, light and easily digestible",
            aiInsight: "Smart choice after digestive distress",
            aiSuggestion: "Add probiotic yogurt to support gut recovery",
            isProcessing: false
        ))

        // MARK: - Day -10

        entries.append(HealthEntry(
            date: date(daysAgo: 10, hour: 8),
            rawText: "Greek yogurt, granola, orange juice",
            entryType: .food,
            calories: 380, protein: 18, carbs: 52, fat: 8,
            aiSummary: "Balanced breakfast with probiotics",
            aiInsight: "Good protein and gut-friendly bacteria from yogurt",
            aiSuggestion: "Opt for low-sugar granola when possible",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 10, hour: 10),
            rawText: "Feeling better today, did some light stretching",
            entryType: .mood,
            moodScore: 0.4,
            aiSummary: "Moderate positive mood, recovery day",
            aiInsight: "Gentle movement aids mood recovery",
            aiSuggestion: "Continue light activity, avoid overexertion",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 10, hour: 13),
            rawText: "Turkey sandwich on whole wheat, apple",
            entryType: .food,
            calories: 420, protein: 26, carbs: 48, fat: 12,
            aiSummary: "Balanced whole food lunch",
            aiInsight: "Good fiber and lean protein combination",
            aiSuggestion: "Excellent choice, maintain this pattern",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 10, hour: 19),
            rawText: "Salmon fillet with roasted vegetables and quinoa",
            entryType: .food,
            calories: 560, protein: 42, carbs: 38, fat: 18,
            aiSummary: "High-quality protein dinner with omega-3s",
            aiInsight: "Salmon provides anti-inflammatory omega-3 fatty acids",
            aiSuggestion: "Aim for salmon or similar fish 2-3 times per week",
            isProcessing: false
        ))

        // MARK: - Day -9

        entries.append(HealthEntry(
            date: date(daysAgo: 9, hour: 7),
            rawText: "Scrambled eggs, whole grain toast, green tea",
            entryType: .food,
            calories: 310, protein: 18, carbs: 32, fat: 12,
            aiSummary: "Solid protein-rich breakfast",
            aiInsight: "Green tea provides gentle caffeine with L-theanine",
            aiSuggestion: "Great morning fuel combination",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 9, hour: 8),
            rawText: "Amazing workout at the gym this morning! Feeling strong and motivated",
            entryType: .mood,
            moodScore: 0.8,
            aiSummary: "High positive mood after gym session",
            aiInsight: "Intense exercise triggers endorphin release",
            aiSuggestion: "Keep this workout routine, it's clearly benefiting your mood",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 9, hour: 12),
            rawText: "Veggie wrap with hummus and mixed greens",
            entryType: .food,
            calories: 390, protein: 14, carbs: 52, fat: 14,
            aiSummary: "Plant-based lunch with healthy fats",
            aiInsight: "Hummus provides plant protein and fiber",
            aiSuggestion: "Add a protein boost like grilled chicken or chickpeas",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 9, hour: 18),
            rawText: "Lentil soup with whole grain bread",
            entryType: .food,
            calories: 420, protein: 22, carbs: 62, fat: 8,
            aiSummary: "High-fiber plant protein dinner",
            aiInsight: "Lentils provide excellent fiber for gut health",
            aiSuggestion: "Excellent plant-based protein source",
            isProcessing: false
        ))

        // MARK: - Day -8

        entries.append(HealthEntry(
            date: date(daysAgo: 8, hour: 8),
            rawText: "Pancakes with syrup, 2 coffees, orange juice",
            entryType: .food,
            calories: 680, protein: 12, carbs: 108, fat: 18,
            aiSummary: "High-sugar, high-carb breakfast",
            aiInsight: "Syrup and juice spike blood sugar rapidly",
            aiSuggestion: "Swap syrup for fresh fruit and add protein",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 8, hour: 13),
            rawText: "Burger and onion rings from Five Guys",
            entryType: .food,
            calories: 920, protein: 38, carbs: 82, fat: 48,
            aiSummary: "Very high calorie fast food lunch",
            aiInsight: "One meal accounts for nearly half of daily caloric needs",
            aiSuggestion: "Balance with a light vegetable dinner tonight",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 8, hour: 15),
            rawText: "Feeling heavy and tired, too much coffee making me anxious, work is overwhelming",
            entryType: .mood,
            moodScore: -0.4,
            aiSummary: "Low mood, caffeine anxiety and stress",
            aiInsight: "High caffeine amplifies anxiety when combined with work stress",
            aiSuggestion: "Try limiting to one coffee per day and take short breaks",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 8, hour: 19),
            rawText: "Fried chicken and mashed potatoes",
            entryType: .food,
            calories: 780, protein: 44, carbs: 58, fat: 36,
            aiSummary: "High-fat, high-calorie dinner",
            aiInsight: "Third consecutive high-fat meal compounds health risk",
            aiSuggestion: "Tomorrow prioritize vegetables and lean proteins",
            isProcessing: false
        ))

        // MARK: - Day -7

        entries.append(HealthEntry(
            date: date(daysAgo: 7, hour: 6),
            rawText: "Headache again, really bad this time, can't focus",
            entryType: .symptom,
            symptomSeverity: 8,
            symptomName: "Headache",
            aiSummary: "Severe morning headache recurring",
            aiInsight: "Pattern: headaches follow high-caffeine days",
            aiSuggestion: "Try eliminating energy drinks for 2 weeks",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 7, hour: 9),
            rawText: "Herbal tea, banana, plain yogurt",
            entryType: .food,
            calories: 180, protein: 6, carbs: 38, fat: 2,
            aiSummary: "Light recovery breakfast",
            aiInsight: "Herbal tea and banana are gentle headache-recovery foods",
            aiSuggestion: "Stay well hydrated throughout the day",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 7, hour: 14),
            rawText: "Headache easing but still not feeling well",
            entryType: .mood,
            moodScore: -0.2,
            aiSummary: "Mild negative mood, recovering from headache",
            aiInsight: "Mood is suppressed by ongoing physical discomfort",
            aiSuggestion: "Rest, hydration, and a short walk may help",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 7, hour: 19),
            rawText: "Chicken soup and crackers",
            entryType: .food,
            calories: 280, protein: 18, carbs: 32, fat: 6,
            aiSummary: "Light healing dinner",
            aiInsight: "Warm broth supports hydration and recovery",
            aiSuggestion: "Good choice for a recovery day",
            isProcessing: false
        ))

        // MARK: - Day -6

        entries.append(HealthEntry(
            date: date(daysAgo: 6, hour: 8),
            rawText: "Smoothie with spinach, banana, protein powder",
            entryType: .food,
            calories: 320, protein: 24, carbs: 42, fat: 4,
            aiSummary: "Nutrient-dense breakfast smoothie",
            aiInsight: "Excellent protein and micronutrient combination",
            aiSuggestion: "Add chia seeds for extra omega-3 and fiber",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 6, hour: 9),
            rawText: "Went for a 5K run this morning, feeling accomplished",
            entryType: .mood,
            moodScore: 0.6,
            aiSummary: "Positive mood post-exercise",
            aiInsight: "Running 5K demonstrates improving fitness and mental discipline",
            aiSuggestion: "Track your run times to see progress",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 6, hour: 13),
            rawText: "Grilled salmon sushi rolls, miso soup",
            entryType: .food,
            calories: 480, protein: 32, carbs: 58, fat: 12,
            aiSummary: "Japanese-style balanced lunch",
            aiInsight: "Miso provides probiotics, salmon provides omega-3",
            aiSuggestion: "Excellent balanced meal with anti-inflammatory benefits",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 6, hour: 19),
            rawText: "Stir-fried tofu with vegetables and brown rice",
            entryType: .food,
            calories: 440, protein: 22, carbs: 52, fat: 14,
            aiSummary: "Plant-based protein dinner",
            aiInsight: "Tofu provides complete protein with low saturated fat",
            aiSuggestion: "Great plant-based meal, well balanced",
            isProcessing: false
        ))

        // MARK: - Day -5

        entries.append(HealthEntry(
            date: date(daysAgo: 5, hour: 8),
            rawText: "Avocado toast with poached eggs, espresso",
            entryType: .food,
            calories: 420, protein: 18, carbs: 38, fat: 22,
            aiSummary: "Trendy but nutritious breakfast",
            aiInsight: "Healthy fats and quality protein set a good metabolic tone",
            aiSuggestion: "Use whole grain bread for extra fiber",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 5, hour: 13),
            rawText: "Caesar salad with grilled chicken",
            entryType: .food,
            calories: 520, protein: 36, carbs: 18, fat: 28,
            aiSummary: "High-protein low-carb lunch",
            aiInsight: "Good lean protein, watch caesar dressing sodium",
            aiSuggestion: "Ask for dressing on the side",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 5, hour: 16),
            rawText: "Decent day, feeling calm and productive",
            entryType: .mood,
            moodScore: 0.3,
            aiSummary: "Stable positive mood",
            aiInsight: "Consistent nutrition supports mood stability",
            aiSuggestion: "Keep up the positive momentum",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 5, hour: 19),
            rawText: "Homemade pasta with pesto and pine nuts",
            entryType: .food,
            calories: 640, protein: 18, carbs: 82, fat: 28,
            aiSummary: "Calorie-dense homemade dinner",
            aiInsight: "Pine nuts add healthy fats but increase calorie density",
            aiSuggestion: "Use whole wheat pasta for more fiber",
            isProcessing: false
        ))

        // MARK: - Day -4

        entries.append(HealthEntry(
            date: date(daysAgo: 4, hour: 8),
            rawText: "Cereal with milk, coffee x3, energy bar",
            entryType: .food,
            calories: 580, protein: 14, carbs: 88, fat: 16,
            aiSummary: "High-caffeine, high-sugar morning",
            aiInsight: "Three coffees significantly exceeds recommended daily caffeine",
            aiSuggestion: "Limit to one or two coffees maximum per day",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 4, hour: 12),
            rawText: "Tacos from Taco Bell x3",
            entryType: .food,
            calories: 840, protein: 34, carbs: 98, fat: 36,
            aiSummary: "High-sodium fast food lunch",
            aiInsight: "Processed meat and refined carbs spike blood sugar",
            aiSuggestion: "Try homemade tacos with fresh ingredients",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 4, hour: 17),
            rawText: "Anxiety through the roof today, stressed about presentation, bad stomach cramps",
            entryType: .mood,
            moodScore: -0.5,
            aiSummary: "High stress, poor mood, digestive issues",
            aiInsight: "Stress and caffeine together amplify anxiety significantly",
            aiSuggestion: "Deep breathing, reduce caffeine, and take a short walk",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 4, hour: 20),
            rawText: "Stomach cramps since this afternoon, feeling nauseous",
            entryType: .symptom,
            symptomSeverity: 6,
            symptomName: "Stomach Pain",
            aiSummary: "Evening stomach cramps with nausea",
            aiInsight: "Likely triggered by stress and poor dietary choices today",
            aiSuggestion: "Ginger tea and light food tomorrow",
            isProcessing: false
        ))

        // MARK: - Day -3

        entries.append(HealthEntry(
            date: date(daysAgo: 3, hour: 6),
            rawText: "Headache, neck tension, third time this week",
            entryType: .symptom,
            symptomSeverity: 6,
            symptomName: "Headache",
            aiSummary: "Recurring headache with neck tension",
            aiInsight: "Third headache in a week suggests caffeine and stress triggers",
            aiSuggestion: "Consider consulting a doctor about recurring headaches",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 3, hour: 9),
            rawText: "Plain oatmeal, chamomile tea, water with lemon",
            entryType: .food,
            calories: 210, protein: 6, carbs: 38, fat: 3,
            aiSummary: "Gentle healing breakfast",
            aiInsight: "Chamomile tea has anti-inflammatory and calming properties",
            aiSuggestion: "Great approach for a headache recovery day",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 3, hour: 11),
            rawText: "Trying to take it easy today, headache slowly going away",
            entryType: .mood,
            moodScore: -0.1,
            aiSummary: "Mild negative mood, rest day",
            aiInsight: "Mood is slowly recovering as headache diminishes",
            aiSuggestion: "Continue resting, avoid screens if possible",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 3, hour: 18),
            rawText: "Baked cod, steamed broccoli, sweet potato",
            entryType: .food,
            calories: 380, protein: 32, carbs: 42, fat: 6,
            aiSummary: "Anti-inflammatory dinner",
            aiInsight: "Excellent macro balance with anti-inflammatory vegetables",
            aiSuggestion: "This is exactly what your body needs today",
            isProcessing: false
        ))

        // MARK: - Day -2

        entries.append(HealthEntry(
            date: date(daysAgo: 2, hour: 7),
            rawText: "Overnight oats with chia seeds, berries, almond milk",
            entryType: .food,
            calories: 340, protein: 10, carbs: 52, fat: 10,
            aiSummary: "Fiber-rich breakfast with omega-3",
            aiInsight: "Chia seeds provide omega-3 fatty acids and sustained energy",
            aiSuggestion: "Excellent breakfast preparation habit",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 2, hour: 8),
            rawText: "Went hiking this morning, beautiful views, feeling refreshed and at peace",
            entryType: .mood,
            moodScore: 0.7,
            aiSummary: "High positive mood after outdoor exercise",
            aiInsight: "Nature and exercise together powerfully boost wellbeing",
            aiSuggestion: "Schedule regular outdoor activities",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 2, hour: 13),
            rawText: "Mediterranean bowl with falafel, hummus, tabbouleh",
            entryType: .food,
            calories: 580, protein: 20, carbs: 68, fat: 24,
            aiSummary: "Nutrient-dense Mediterranean lunch",
            aiInsight: "Mediterranean diet is linked to reduced inflammation",
            aiSuggestion: "Excellent dietary pattern to maintain",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 2, hour: 19),
            rawText: "Grilled chicken with roasted asparagus and wild rice",
            entryType: .food,
            calories: 480, protein: 44, carbs: 38, fat: 12,
            aiSummary: "High-protein balanced dinner",
            aiInsight: "Asparagus is rich in folate and antioxidants",
            aiSuggestion: "Ideal macro split for muscle maintenance",
            isProcessing: false
        ))

        // MARK: - Day -1

        entries.append(HealthEntry(
            date: date(daysAgo: 1, hour: 8),
            rawText: "Green smoothie, whole grain toast, green tea",
            entryType: .food,
            calories: 280, protein: 8, carbs: 52, fat: 4,
            aiSummary: "Light nutrient-dense breakfast",
            aiInsight: "Green vegetables provide folate and vitamin K",
            aiSuggestion: "Add protein to this breakfast for better satiety",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 1, hour: 13),
            rawText: "Quinoa bowl with chickpeas, roasted vegetables, tahini",
            entryType: .food,
            calories: 520, protein: 18, carbs: 62, fat: 18,
            aiSummary: "Complete plant protein lunch",
            aiInsight: "Quinoa and chickpeas together form a complete amino acid profile",
            aiSuggestion: "Outstanding plant-based meal",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 1, hour: 15),
            rawText: "Good productive day, feel like I'm making positive changes to my diet",
            entryType: .mood,
            moodScore: 0.5,
            aiSummary: "Positive mood, motivated about health",
            aiInsight: "Awareness of dietary improvement boosts self-efficacy",
            aiSuggestion: "Document your wins to maintain motivation",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 1, hour: 19),
            rawText: "Baked salmon, steamed edamame, brown rice",
            entryType: .food,
            calories: 540, protein: 46, carbs: 48, fat: 16,
            aiSummary: "Excellent balanced dinner",
            aiInsight: "High protein with omega-3 supports recovery and inflammation control",
            aiSuggestion: "This is a benchmark meal for your health goals",
            isProcessing: false
        ))

        // MARK: - Today

        entries.append(HealthEntry(
            date: date(daysAgo: 0, hour: 8),
            rawText: "Greek yogurt parfait with granola and honey",
            entryType: .food,
            calories: 340, protein: 16, carbs: 52, fat: 8,
            aiSummary: "Probiotic-rich balanced breakfast",
            aiInsight: "Greek yogurt supports gut microbiome health",
            aiSuggestion: "Add fresh fruit for extra vitamins",
            isProcessing: false
        ))

        entries.append(HealthEntry(
            date: date(daysAgo: 0, hour: 9),
            rawText: "Morning meditation, feeling clear-headed and ready for the day",
            entryType: .mood,
            moodScore: 0.6,
            aiSummary: "Calm positive morning mood",
            aiInsight: "Meditation builds emotional resilience and reduces cortisol",
            aiSuggestion: "Keep this morning mindfulness practice going",
            isProcessing: false
        ))

        for entry in entries {
            context.insert(entry)
        }
    }
}
