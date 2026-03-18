namespace :markets do
  desc 'Create example markets with articles (requires at least one user)'
  task create_examples: :environment do
    owner = User.first

    if owner.nil?
      puts 'No users found. Create a user first (e.g. rake users:create_root).'
      exit
    end

    hungry_owner = User.find_or_initialize_by(email: 'max@hungry')
    hungry_owner.assign_attributes(name: 'Max', password: 'qweasd234', password_confirmation: 'qweasd234')
    hungry_owner.save!

    puts 'Creating example markets...'

    markets_data = {
      'Hungry' => [
        { title: 'Класична', unlimited: true,
          description: 'Лаваш, пилетина, поврће, сос од павлаке и белог лука',
          variants: [ { name: 'M', price: 530 }, { name: 'L', price: 680 }, { name: 'XXL', price: 830 } ] },
        { title: 'Са сиром', unlimited: true,
          description: 'Лаваш, пилетина, поврће, сос од павлаке и белог лука, гауда',
          variants: [ { name: 'M', price: 580 }, { name: 'L', price: 730 }, { name: 'XXL', price: 830 } ] },
        { title: 'Са помфритом', unlimited: true,
          description: 'Лаваш, пилетина, поврће, сос од павлаке и белог лука, помфрит',
          variants: [ { name: 'M', price: 580 }, { name: 'L', price: 730 }, { name: 'XXL', price: 880 } ] },
        { title: 'Шаурма на тањиру', unlimited: true,
          description: 'Пилетина, поврће, сос од павлаке и белог лука, помфрит / village krompir, лаваш',
          variants: [ { price: 830 } ] },
        { title: 'Са љутом шаргарепом', unlimited: true,
          description: 'Лаваш, пилетина, поврће, сос од павлаке и белог лука, зачињена шаргарепа',
          variants: [ { name: 'M', price: 580 }, { name: 'L', price: 730 }, { name: 'XXL', price: 880 } ] },
        { title: 'Од главног кувара', unlimited: true,
          description: 'Лаваш, пилетина, поврће, сос од павлаке и белог лука, гауда, црвени лук, љути сос',
          variants: [ { name: 'L', price: 780 }, { name: 'XXL', price: 930 } ] },
        { title: 'Village krompir sa kiselim krastavcem', unlimited: true,
          description: 'Лаваш, пилетина, поврће, сос од павлаке и белог лука, пржени лук, кисели краставац',
          variants: [ { name: 'L', price: 780 }, { name: 'XXL', price: 930 } ] },
        { title: 'Са прженим луком и киселим краставцем', unlimited: true,
          description: 'Лаваш, пилетина, поврће, сос од павлаке и белог лука, пржени лук, кисели краставац',
          variants: [ { name: 'L', price: 780 }, { name: 'XXL', price: 930 } ] },
        { title: 'Bacon BBQ sos', unlimited: true,
          description: 'Лаваш, пилетина, поврће, сос од павлаке и белог лука, bacon, BBQ сос',
          variants: [ { name: 'L', price: 780 }, { name: 'XXL', price: 930 } ] }
      ],
      'Green Garden' => [
        { title: 'Organic Avocados', description: 'Pack of 4, ripe', stock: 200, variants: [ { price: 470 } ] },
        { title: 'Cherry Tomatoes', description: 'Vine-ripened, 500g', stock: 150, variants: [ { price: 270 } ] },
        { title: 'Baby Spinach', description: 'Washed and ready, 200g', stock: 100, variants: [ { price: 230 } ] },
        { title: 'Blueberries', description: 'Fresh, 250g punnet', stock: 80, variants: [ { price: 390 } ] },
        { title: 'Sweet Potatoes', description: 'Organic, 1kg', stock: 120, variants: [ { price: 310 } ] }
      ],
      'Ocean Catch' => [
        { title: 'Atlantic Salmon Fillet', description: 'Fresh, 200g portion', stock: 40,
          variants: [ { price: 780 } ] },
        { title: 'Tiger Prawns', description: 'Raw, peeled, 300g', stock: 35, variants: [ { price: 970 } ] },
        { title: 'Smoked Mackerel', description: 'Whole fillet, 180g', stock: 50, variants: [ { price: 460 } ] },
        { title: 'Tuna Steak', description: 'Sashimi grade, 150g', stock: 25, variants: [ { price: 930 } ] }
      ]
    }

    created_markets = 0
    created_articles = 0

    markets_data.each do |market_name, articles|
      market_owner = market_name == 'Hungry' ? hungry_owner : owner
      market = market_owner.markets.find_or_initialize_by(name: market_name)

      unless market.save
        puts "Failed to create market '#{market_name}': #{market.errors.full_messages.join(', ')}"
        next
      end

      created_markets += 1

      articles.each do |attrs|
        variant_attrs = attrs.delete(:variants)
        article = market.articles.find_or_initialize_by(title: attrs[:title])
        article.assign_attributes(attrs)
        variant_attrs.each do |v|
          article.article_variants.find_or_initialize_by(name: v[:name]).tap { |av| av.price = v[:price] }
        end

        if article.save
          created_articles += 1
          print '.'
        else
          puts "\nFailed to create article '#{attrs[:title]}': #{article.errors.full_messages.join(', ')}"
        end
      end
    end

    puts "\n\nCompleted!"
    puts "Markets: #{created_markets}"
    puts "Articles: #{created_articles}"
  end

  desc 'Delete all example markets and their articles'
  task delete_examples: :environment do
    names = [ 'Hungry', 'Green Garden', 'Ocean Catch' ]
    markets = Market.where(name: names)
    count = markets.count

    if count.zero?
      puts 'No example markets found.'
    else
      markets.destroy_all
      puts "Deleted #{count} example markets and their articles."
    end
  end
end
