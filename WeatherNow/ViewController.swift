//
//  ViewController.swift
//  WeatherNow
//
//  Created by Sepehr Keyhani on 10/20/25.
//

import UIKit
import SnapKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate {

    // Controls
    private let searchField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "City name..."
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .words
        tf.returnKeyType = .search
        return tf
    }()

    private let searchButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Search", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .systemBlue
        btn.layer.cornerRadius = 8
        return btn
    }()

    private let cardView = UIView()
    private let cardGradient = CAGradientLayer()
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .secondaryLabel
        return iv
    }()
    private let cityLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .title2)
        l.textAlignment = .center
        l.numberOfLines = 1
        return l
    }()
    private let tempLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 42, weight: .semibold)
        l.textAlignment = .center
        return l
    }()
    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .subheadline)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()
    private let errorLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .body)
        l.textAlignment = .center
        l.textColor = .systemOrange
        l.numberOfLines = 0
        l.isHidden = true
        return l
    }()
    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.hidesWhenStopped = true
        return s
    }()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var searchTask: Task<Void, Never>?
    private let selectedCityLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .headline)
        l.textColor = .label
        l.numberOfLines = 1
        l.isHidden = true
        return l
    }()
    private let favoriteButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "star"), for: .normal)
        b.tintColor = .systemYellow
        b.isHidden = true
        return b
    }()

    // MVVM
    private var viewModel: WeatherViewModel!

    private let locationService = LocationService()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "WeatherNow"
        view.backgroundColor = .systemGroupedBackground

        let service = WeatherService()
        let cache = WeatherCache()
        viewModel = WeatherViewModel(service: service, cache: cache)
        viewModel.onChange = { [weak self] state in self?.render(state) }

        layoutUI()
        bindActions()
        render(viewModel.state)

        // Request location on launch and load; fallback to Ottawa if denied
        Task { [weak self] in
            guard let self else { return }
            if let coord = await self.locationService.requestCurrentLocation() {
                print("[WeatherNow] CurrentLocation lat=\(coord.latitude), lon=\(coord.longitude)")
                await self.viewModel.loadByCoordinates(lat: coord.latitude, lon: coord.longitude)
            } else {
                // Ottawa, Canada
                print("[WeatherNow] Location denied/unavailable. Falling back to Ottawa search")
                await self.viewModel.search(city: "Ottawa")
            }
        }
    }

    private func layoutUI() {
        view.addSubview(searchField)
        view.addSubview(searchButton)
        view.addSubview(selectedCityLabel)
        view.addSubview(cardView)
        view.addSubview(errorLabel)
        view.addSubview(spinner)
        view.addSubview(tableView)
        view.addSubview(favoriteButton)

        searchField.delegate = self

        searchField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().inset(16)
        }

        searchButton.snp.makeConstraints { make in
            make.centerY.equalTo(searchField)
            make.leading.equalTo(searchField.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(16)
            make.width.equalTo(90)
        }

        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 16
        cardView.clipsToBounds = true
        // Theming: soft gradient background for the card
        cardGradient.colors = [
            UIColor.systemGray6.cgColor,
            UIColor.systemGray5.cgColor
        ]
        cardGradient.startPoint = CGPoint(x: 0, y: 0)
        cardGradient.endPoint = CGPoint(x: 1, y: 1)
        cardView.layer.insertSublayer(cardGradient, at: 0)

        selectedCityLabel.snp.makeConstraints { make in
            make.top.equalTo(searchField.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 56
        tableView.snp.makeConstraints { make in
            make.top.equalTo(selectedCityLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        cardView.snp.makeConstraints { make in
            make.top.equalTo(selectedCityLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        cardView.addSubview(iconView)
        cardView.addSubview(cityLabel)
        cardView.addSubview(tempLabel)
        cardView.addSubview(descLabel)

        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }
        cityLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        tempLabel.snp.makeConstraints { make in
            make.top.equalTo(cityLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(tempLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(16)
        }

        errorLabel.snp.makeConstraints { make in
            make.top.equalTo(cardView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        spinner.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(errorLabel.snp.bottom).offset(16)
        }

        favoriteButton.snp.makeConstraints { make in
            make.trailing.equalTo(cardView.snp.trailing).inset(12)
            make.top.equalTo(cardView.snp.top).offset(12)
            make.width.height.equalTo(28)
        }

        // table overlays content and fills to bottom; visibility toggled in render
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cardGradient.frame = cardView.bounds
        cardGradient.cornerRadius = cardView.layer.cornerRadius
    }

    private func bindActions() {
        searchButton.addTarget(self, action: #selector(didTapSearch), for: .touchUpInside)
        searchField.addTarget(self, action: #selector(searchEditingChanged), for: .editingChanged)
        favoriteButton.addTarget(self, action: #selector(didTapFavoriteOnCard), for: .touchUpInside)
    }

    @objc private func didTapSearch() {
        let city = searchField.text ?? ""
        Task { await viewModel.liveSearchPlaces(query: city) }
        searchField.resignFirstResponder()
        tableView.isHidden = false
    }

    @objc private func searchEditingChanged() {
        let text = searchField.text ?? ""
        searchTask?.cancel()
        tableView.isHidden = false
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard !Task.isCancelled else { return }
            await self?.viewModel.liveSearchPlaces(query: text)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didTapSearch()
        return true
    }

    private func render(_ state: WeatherViewModel.State) {
        if state.isLoading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }

        if let weather = state.weather {
            cardView.isHidden = false
            errorLabel.isHidden = true
            cityLabel.text = weather.city
            tempLabel.text = weather.formattedTemperature
            descLabel.text = weather.conditionDescription
            iconView.image = UIImage(systemName: weather.symbolName)
            favoriteButton.isHidden = false
            let isFav = viewModel.isCurrentWeatherFavorite()
            favoriteButton.setImage(UIImage(systemName: isFav ? "star.fill" : "star"), for: .normal)
        } else {
            cardView.isHidden = true
            favoriteButton.isHidden = true
        }

        if let error = state.errorMessage {
            errorLabel.text = error
            errorLabel.isHidden = false
        } else if state.weather == nil && !state.isLoading {
            errorLabel.text = state.showingFavorites ? "Favorites" : ""
            errorLabel.isHidden = false
        } else {
            errorLabel.isHidden = true
        }

        let rows = state.showingFavorites ? state.favorites.count : state.places.count
        let shouldShowList = rows > 0
        tableView.isHidden = !shouldShowList
        tableView.reloadData()

        // Selected city title above card
        if let title = state.headerTitle, !title.isEmpty {
            selectedCityLabel.text = title
            selectedCityLabel.isHidden = false
        } else if let weather = state.weather, !weather.city.isEmpty {
            selectedCityLabel.text = weather.city
            selectedCityLabel.isHidden = false
        } else {
            selectedCityLabel.isHidden = true
        }
    }

    @objc private func didTapFavoriteOnCard() {
        viewModel.toggleFavoriteForCurrentWeather()
        let isFav = viewModel.isCurrentWeatherFavorite()
        favoriteButton.setImage(UIImage(systemName: isFav ? "star.fill" : "star"), for: .normal)
    }

    // No network icon loads; we use SF Symbols based on Open-Meteo codes
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let s = viewModel.state
        let isSearching = !s.places.isEmpty
        if isSearching {
            // Section 0: favorites, Section 1: search results
            return section == 0 ? s.favorites.count : s.places.count
        }
        // Not searching: Section 0 current city summary (1 row), Section 1 favorites
        return section == 0 ? 1 : s.favorites.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let s = viewModel.state
        let isSearching = !s.places.isEmpty
        if isSearching {
            return section == 0 ? "Favorite cities" : nil
        } else {
            return section == 1 ? "Favorite cities" : nil
        }
        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 && !viewModel.state.places.isEmpty { return separatorView() }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 && !viewModel.state.places.isEmpty { return 1 } else { return 0.01 }
    }

    private func separatorView() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        return v
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let s = viewModel.state
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        cell.backgroundColor = .systemBackground

        let isSearching = !s.places.isEmpty
        if isSearching {
            if indexPath.section == 0 {
                // favorites first
                let place = s.favorites[indexPath.row]
                config.text = place.displayName
                if let w = viewModel.weatherForFavorite(place) { config.secondaryText = w.formattedTemperature } else { config.secondaryText = "--" }
                cell.accessoryView = starAccessory(for: place, isStarred: true)
            } else {
                // then search results
                let place = s.places[indexPath.row]
                config.text = place.displayName
                config.secondaryText = nil
                let isFav = s.favorites.contains(place)
                cell.accessoryView = starAccessory(for: place, isStarred: isFav)
            }
        } else {
            if indexPath.section == 0 {
                // current city summary
                config.text = s.weather?.city ?? ""
                config.secondaryText = s.weather?.formattedTemperature
                cell.accessoryView = favoriteAccessory(isStarred: viewModel.isCurrentWeatherFavorite())
            } else {
                let place = s.favorites[indexPath.row]
                config.text = place.displayName
                if let w = viewModel.weatherForFavorite(place) { config.secondaryText = w.formattedTemperature } else { config.secondaryText = "--" }
                cell.accessoryView = starAccessory(for: place, isStarred: true)
            }
        }

        config.textProperties.numberOfLines = 1
        cell.contentConfiguration = config
        return cell
    }

    private func starAccessory(for place: Place, isStarred: Bool) -> UIView {
        let button = UIButton(type: .system)
        let symbolName = isStarred ? "star.fill" : "star"
        button.setImage(UIImage(systemName: symbolName), for: .normal)
        button.tintColor = isStarred ? .systemYellow : .tertiaryLabel
        button.addAction(UIAction { [weak self] _ in
            self?.viewModel.toggleFavorite(place)
            self?.tableView.reloadData()
        }, for: .touchUpInside)
        return button
    }

    private func favoriteAccessory(isStarred: Bool) -> UIView {
        let button = UIButton(type: .system)
        let symbolName = isStarred ? "star.fill" : "star"
        button.setImage(UIImage(systemName: symbolName), for: .normal)
        button.tintColor = isStarred ? .systemYellow : .tertiaryLabel
        button.addAction(UIAction { [weak self] _ in
            self?.didTapFavoriteOnCard()
            self?.tableView.reloadData()
        }, for: .touchUpInside)
        return button
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let s = viewModel.state
        let isSearching = !s.places.isEmpty
        if isSearching {
            if indexPath.section == 0 {
                let place = s.favorites[indexPath.row]
                Task { await viewModel.selectPlace(place) }
                tableView.isHidden = true
                searchField.text = place.name
            } else {
                let place = s.places[indexPath.row]
                Task { await viewModel.selectPlace(place) }
                tableView.isHidden = true
                searchField.text = place.name
            }
        } else {
            if indexPath.section == 1 {
                let place = s.favorites[indexPath.row]
                Task { await viewModel.selectPlace(place) }
                tableView.isHidden = true
                searchField.text = place.name
            }
        }
    }
}

