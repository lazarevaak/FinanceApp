import UIKit
import Combine

final class AnalysisViewController: UIViewController {

    var onBack: (() -> Void)?

    private let viewModel: AnalysisViewModel
    private var bag = Set<AnyCancellable>()

    private let startDatePicker = UIDatePicker()
    private let endDatePicker   = UIDatePicker()
    private let sumLabel        = UILabel()
    private let tableView       = UITableView(frame: .zero, style: .plain)
    private let sortControl: UISegmentedControl = {
        let c = UISegmentedControl(items: ["По дате", "По сумме"])
        c.selectedSegmentIndex = 0
        c.selectedSegmentTintColor = .white
        c.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .selected)
        c.setTitleTextAttributes([.foregroundColor: UIColor.secondaryLabel], for: .normal)
        return c
    }()

    init(direction: Direction,
         accountId: Int,
         client: NetworkClient) {
        self.viewModel = AnalysisViewModel(client: client,
                                           accountId: accountId,
                                           direction: direction)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        view.tintColor = .black
        setupHeader()
        setupSubviews()
        bindVM()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: Header
    private func setupHeader() {
        let back = UIButton(type: .system)
        back.setTitle("Назад", for: .normal)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.semanticContentAttribute = .forceLeftToRight
        back.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)

        let title = UILabel()
        title.text = "Анализ"
        title.font = .systemFont(ofSize: 34, weight: .bold)

        let backStack = UIStackView(arrangedSubviews: [back, UIView()])
        backStack.axis = .horizontal
        backStack.alignment = .center
        backStack.spacing = 8
        backStack.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(backStack)
        view.addSubview(title)

        NSLayoutConstraint.activate([
            backStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            title.topAnchor.constraint(equalTo: backStack.bottomAnchor, constant: 8),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
    }
    @objc private func didTapBack() { onBack?() }

    // MARK: Subviews
    private func setupSubviews() {
        [startDatePicker, endDatePicker].forEach {
            $0.datePickerMode = .date
            $0.preferredDatePickerStyle = .compact
            $0.tintColor = .systemGreen
            $0.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        }
        sortControl.addTarget(self, action: #selector(sortChanged(_:)), for: .valueChanged)

        let periodStack = UIStackView(arrangedSubviews: [
            row("Период: начало", pickerContainer(startDatePicker)),
            sep(),
            row("Период: конец",  pickerContainer(endDatePicker)),
            sep(),
            row("Сортировка", sortControl),
            sep(),
            row("Сумма", sumLabel)
        ])
        periodStack.axis = .vertical
        periodStack.spacing = 1
        periodStack.layer.cornerRadius = 12
        periodStack.backgroundColor = .systemBackground
        periodStack.translatesAutoresizingMaskIntoConstraints = false

        let opsHeader = UILabel()
        opsHeader.text = "ОПЕРАЦИИ"
        opsHeader.font = .preferredFont(forTextStyle: .caption1)
        opsHeader.textColor = .secondaryLabel
        opsHeader.translatesAutoresizingMaskIntoConstraints = false

        tableView.register(AnalysisCell.self,
                           forCellReuseIdentifier: AnalysisCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0)
        tableView.layer.cornerRadius = 12
        tableView.clipsToBounds = true
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(periodStack)
        view.addSubview(opsHeader)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            periodStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 105),
            periodStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            periodStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            opsHeader.topAnchor.constraint(equalTo: periodStack.bottomAnchor, constant: 16),
            opsHeader.leadingAnchor.constraint(equalTo: periodStack.leadingAnchor),

            tableView.topAnchor.constraint(equalTo: opsHeader.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func pickerContainer(_ picker: UIDatePicker) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        container.layer.cornerRadius = 8
        picker.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            picker.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
            picker.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            picker.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8)
        ])
        return container
    }
    private func row(_ title: String, _ ctrl: UIView) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 17)
        if title.contains("Период") {
            label.widthAnchor.constraint(equalToConstant: 200).isActive = true
        }
        let row = UIStackView(arrangedSubviews: [label, ctrl])
        row.axis = .horizontal
        row.spacing = 12
        row.layoutMargins = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        row.isLayoutMarginsRelativeArrangement = true
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return row
    }
    private func sep() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.6)
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    // MARK: Binding
    private func bindVM() {
        startDatePicker.date = viewModel.startDate
        endDatePicker.date   = viewModel.endDate
        updateSum()

        viewModel.onUpdate = { [weak self] in
            self?.updateSum()
            self?.tableView.reloadData()
        }

        viewModel.$alertError
            .compactMap { $0 }
            .sink { [weak self] msg in
                let alert = UIAlertController(title: "Ошибка", message: msg, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
            .store(in: &bag)
    }

    private func updateSum() {
        let code = UserDefaults.standard.string(forKey: "currencyCode") ?? "RUB"
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencyCode = code
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.maximumFractionDigits = 0
        sumLabel.text = fmt.string(from: viewModel.total as NSDecimalNumber)
    }

    // MARK: Actions
    @objc private func dateChanged(_ sender: UIDatePicker) {
        if sender == startDatePicker {
            viewModel.startDate = sender.date
        } else {
            viewModel.endDate = sender.date
        }
    }
    @objc private func sortChanged(_ sender: UISegmentedControl) {
        viewModel.sortOption = sender.selectedSegmentIndex == 1 ? .byAmount : .byDate
    }
}

// MARK: UITableViewDataSource / UITableViewDelegate
extension AnalysisViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.transactions.count
    }
    func tableView(_ tv: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: AnalysisCell.reuseIdentifier,
                                          for: indexPath) as! AnalysisCell
        let tx = viewModel.transactions[indexPath.row]
        let code = UserDefaults.standard.string(forKey: "currencyCode") ?? "RUB"
        cell.configure(with: tx, total: viewModel.total, currencyCode: code)
        return cell
    }
}
