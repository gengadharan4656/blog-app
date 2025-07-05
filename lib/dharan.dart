import 'package:flutter/material.dart';

void main() {
  runApp(BlogApp());
}

class BlogApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Blog',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: BlogHomePage(),
    );
  }
}

class BlogPost {
  final String title;
  final String content;

  BlogPost({required this.title, required this.content});
}

class BlogHomePage extends StatelessWidget {
  final List<BlogPost> posts = [
    BlogPost(
      title: 'cricket Blog',
      content: """Sure! Here's a **sample blog post about cricket** that you can plug into your Flutter blog app or publish online. This is written in a friendly, engaging tone and gives an overview of the sport.

  ---

  ## 🏏 **Title:** *The Gentleman's Game: A Love Letter to Cricket*

  **Author:** Admin
  **Date:** June 17, 2025

  ---

  ### 🏆 Introduction

  Cricket — more than just a sport — is a passion, a tradition, and a way of life for millions around the world. From the bustling streets of Mumbai to the green fields of London, cricket brings people together through its thrilling pace, historic rivalries, and moments of pure magic.

  ---

  ### 🌍 A Global Sport

  While cricket began in England, it has grown into a global phenomenon. Today, countries like India, Australia, Pakistan, South Africa, and New Zealand are not just competitive — they’re cricket-obsessed.

  Each region adds its own flavor:

  * India is known for its unmatchable crowd energy and legendary icons like Sachin Tendulkar and Virat Kohli.
  * Australia brings aggressive, tactical play.
  * England offers a blend of tradition and innovation, especially with formats like *The Hundred*.

  ---

  ### ⏳ Formats for Every Fan

  One reason cricket has evolved so well is its **different formats**:

  * **Test Matches** – The longest and most traditional form. Played over 5 days.
  * **One Day Internationals (ODIs)** – 50 overs per side. Ideal balance of patience and excitement.
  * **T20s** – The fast-paced, 3-hour thrill ride that has taken over the world, thanks to leagues like the IPL.

  Whether you're a traditionalist or a thrill-seeker, cricket has something for everyone.

  ---

  ### 🌟 Legendary Moments

  Here are just a few iconic memories that cricket fans cherish:

  * MS Dhoni's World Cup-winning six in 2011
  * Ben Stokes' heroic Ashes performance in 2019
  * Yuvraj Singh's six 6s in an over
  * The drama of Super Overs in T20 World Cups

  ---

  ### 🧒 Why We Love It

  Cricket is more than bat and ball. It’s:

  * A summer memory
  * A family ritual
  * A street tournament with taped tennis balls
  * A conversation starter in any corner of the world

  It teaches patience, teamwork, strategy, and respect.

  ---

  ### 📢 Final Word

  Cricket is ever-evolving, from white kits and red balls to colored jerseys and blazing boundaries. Yet, its spirit remains untouched — uniting nations, creating heroes, and telling stories that last generations.

  So next time you hear the sound of ball hitting bat — pause, smile, and know that you're hearing the heartbeat of millions.

  ---
  """,
    ),
    BlogPost(
      title: 'football blog',
      content: """Absolutely! Here's a complete **football blog post** you can use for your Flutter blog app or any blog website. It captures the excitement, culture, and global impact of the game.

  ---

  ## ⚽ **Title:** *Football: The Beautiful Game That Unites the World*

  **Author:** Admin
  **Date:** June 17, 2025

  ---

  ### 🌍 A Global Language

  Football — or soccer, as it’s known in some countries — is more than just the world’s most popular sport. It's a universal language, spoken in stadiums, streets, and schoolyards from Rio to Riyadh, London to Lagos.

  With over 4 billion fans across continents, football unites people of all cultures, ages, and backgrounds.

  ---

  ### 🏟️ The Power of Passion

  What makes football so special?

  * **Simplicity**: All you need is a ball — no fancy equipment required.
  * **Drama**: Goals in the final seconds, penalty shootouts, underdog wins — football is packed with emotion.
  * **Loyalty**: Club rivalries like *Barcelona vs Real Madrid*, *Liverpool vs Manchester United*, and *Boca Juniors vs River Plate* are more than matches — they're cultural events.

  ---

  ### 🌟 Legends of the Game

  Football has given us icons whose names will be remembered for generations:

  * **Pelé** – The King of Football
  * **Diego Maradona** – The Hand of God and one of the greatest ever
  * **Lionel Messi** – The magician of modern football
  * **Cristiano Ronaldo** – A machine of goals and greatness

  These players aren’t just athletes — they’re heroes, role models, and symbols of hope.

  ---

  ### 🏆 The World Cup: Where Dreams Come True

  Every four years, the **FIFA World Cup** captures the world’s imagination. Nations come together, heroes are made, and unforgettable moments are born:

  * *Zidane's headbutt in 2006*
  * *Spain’s golden generation in 2010*
  * *Messi’s fairytale win in 2022*

  It’s not just a tournament — it’s a global festival.

  ---

  ### 🧒 More Than a Game

  Football builds:

  * **Community** – Local teams and street matches create bonds.
  * **Character** – Teamwork, discipline, and resilience are learned on the pitch.
  * **Hope** – For many kids in disadvantaged regions, football is a path to a better life.

  ---

  ### ⚡ The Future of Football

  With growing investments, technology like VAR, and inclusive movements (women’s football, para-football), the sport is more dynamic than ever.

  And with stars like Kylian Mbappé, Erling Haaland, and Jude Bellingham rising, the next era looks just as thrilling.

  ---

  ### 📢 Final Whistle

  Football isn’t just a 90-minute game — it’s a way of life. It breaks language barriers, fuels dreams, and reminds us that in the end, we're all playing on the same field.

  Whether you’re watching in a packed stadium or kicking a ball down an alley, you’re part of something bigger — part of the beautiful game.

  ---

  Would you like me to format this into a Flutter widget, Markdown for rendering, or save it as a file?
  """,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Flutter Blog')),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return ListTile(
            title: Text(post.title),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlogDetailPage(post: post),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BlogDetailPage extends StatelessWidget {
  final BlogPost post;

  BlogDetailPage({required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(post.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(post.content, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
