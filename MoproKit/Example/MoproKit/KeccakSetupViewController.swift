//
//  ViewController.swift
//  MoproKit
//
//  Created by 1552237 on 09/16/2023.
//  Copyright (c) 2023 1552237. All rights reserved.
//

import MoproKit
import UIKit

class KeccakSetupViewController: UIViewController {

  let zkeyUrl = URL(string: "https://mopro.vivianjeng.xyz/keccak256_256_test_final.zkey")
  let wasmUrl = URL(string: "https://mopro.vivianjeng.xyz/keccak256_256_test.wasm")

  var downloadButton = UIButton(type: .system)
  var setupButton = UIButton(type: .system)
  var proveButton = UIButton(type: .system)
  var verifyButton = UIButton(type: .system)
  var textView = UITextView()

  let moproCircom = MoproKit.MoproCircom()
  var generatedProof: Data?
  var publicInputs: Data?

  override func viewDidLoad() {
    super.viewDidLoad()

    // Set title
    let title = UILabel()
    title.text = "Keccak256 (setup)"
    title.textColor = .white
    title.textAlignment = .center
    navigationItem.titleView = title
    navigationController?.navigationBar.isHidden = false
    navigationController?.navigationBar.prefersLargeTitles = true

    // view.backgroundColor = .white
    // navigationController?.navigationBar.prefersLargeTitles = true
    // navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
    // navigationController?.navigationBar.barTintColor = UIColor.white // or any other contrasting color
    // self.title = "Keccak256 (setup)"

    setupUI()
  }

  func setupUI() {
    downloadButton.setTitle("Download Ark Zkey", for: .normal)
    setupButton.setTitle("Setup", for: .normal)
    proveButton.setTitle("Prove", for: .normal)
    verifyButton.setTitle("Verify", for: .normal)

    textView.isEditable = false

    //self.title = "Keccak256 (setup)"
    //view.backgroundColor = .black

    // Setup actions for buttons
    downloadButton.addTarget(self, action: #selector(runDownloadAction), for: .touchUpInside)
    setupButton.addTarget(self, action: #selector(runSetupAction), for: .touchUpInside)
    proveButton.addTarget(self, action: #selector(runProveAction), for: .touchUpInside)
    verifyButton.addTarget(self, action: #selector(runVerifyAction), for: .touchUpInside)

    downloadButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    setupButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    proveButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    verifyButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

    let stackView = UIStackView(arrangedSubviews: [
      downloadButton, setupButton, proveButton, verifyButton, textView,
    ])
    stackView.axis = .vertical
    stackView.spacing = 10
    stackView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stackView)

    // Make text view visible
    textView.heightAnchor.constraint(equalToConstant: 200).isActive = true

    NSLayoutConstraint.activate([
      stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
    ])
  }

  @objc func runDownloadAction() {
    let zkeyStart = CFAbsoluteTimeGetCurrent()
    FileDownloader.loadFileAsync(url: self.zkeyUrl!) { (path, error) in
      print("Zkey File downloaded to : \(path!)")
      let zkeyEnd = CFAbsoluteTimeGetCurrent()
      print("Download ark key took:", zkeyEnd - zkeyStart)
    }

    let wasmStart = CFAbsoluteTimeGetCurrent()
    FileDownloader.loadFileAsync(url: self.wasmUrl!) { (path, error) in
      print("wasm File downloaded to : \(path!)")
      let wasmEnd = CFAbsoluteTimeGetCurrent()
      print("Download wasm took:", wasmEnd - wasmStart)
    }

  }

  @objc func runSetupAction() {
    // Logic for setup
    if let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      .first
    {

      let zkeyPath = documentsUrl.appendingPathComponent((zkeyUrl!).lastPathComponent)
      let wasmPath = documentsUrl.appendingPathComponent((wasmUrl!).lastPathComponent)

      // Multiplier example
      // if let wasmPath = Bundle.main.path(forResource: "multiplier2", ofType: "wasm"),
      //    let r1csPath = Bundle.main.path(forResource: "multiplier2", ofType: "r1cs") {

      do {
        textView.text += "Initializing library\n"
        // Record start time
        let start = CFAbsoluteTimeGetCurrent()

        try moproCircom.initialize(zkeyPath: zkeyPath.path, wasmPath: wasmPath.path)
        proveButton.isEnabled = true  // Enable the Prove button upon successful setup

        // Record end time and compute duration
        let end = CFAbsoluteTimeGetCurrent()
        let timeTaken = end - start

        textView.text += "Initializing zkey and wasm took \(timeTaken) seconds.\n"
      } catch let error as MoproError {
        print("MoproError: \(error)")
      } catch {
        print("Unexpected error: \(error)")
      }
    } else {
      print("Error getting paths for resources")
    }
  }

  @objc func runProveAction() {
    // Logic for prove
    guard proveButton.isEnabled else {
      print("Setup is not completed yet.")
      return
    }
    do {
      // Prepare inputs
      let inputVec: [UInt8] = [
        116, 101, 115, 116, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
      ]
      let bits = bytesToBits(bytes: inputVec)
      var inputs = [String: [String]]()
      inputs["in"] = bits

      // Multiplier example
      // var inputs = [String: [String]]()
      // let a = 3
      // let b = 5
      // inputs["a"] = [String(a)]
      // inputs["b"] = [String(b)]

      // Record start time
      let start = CFAbsoluteTimeGetCurrent()

      // Generate Proof
      let generateProofResult = try moproCircom.generateProof(circuitInputs: inputs)
      assert(!generateProofResult.proof.isEmpty, "Proof should not be empty")

      // Record end time and compute duration
      let end = CFAbsoluteTimeGetCurrent()
      let timeTaken = end - start

      // Store the generated proof and public inputs for later verification
      generatedProof = generateProofResult.proof
      publicInputs = generateProofResult.inputs

      textView.text += "Proof generation took \(timeTaken) seconds.\n"
      verifyButton.isEnabled = true  // Enable the Verify button once proof has been generated
    } catch let error as MoproError {
      print("MoproError: \(error)")
    } catch {
      print("Unexpected error: \(error)")
    }
  }

  @objc func runVerifyAction() {
    // Logic for verify
    guard let proof = generatedProof,
      let publicInputs = publicInputs
    else {
      print("Setup is not completed or proof has not been generated yet.")
      return
    }
    do {
      // Verify Proof
      let isValid = try moproCircom.verifyProof(proof: proof, publicInput: publicInputs)
      assert(isValid, "Proof verification should succeed")

      textView.text += "Proof verification succeeded.\n"
    } catch let error as MoproError {
      print("MoproError: \(error)")
    } catch {
      print("Unexpected error: \(error)")
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

func bytesToBits(bytes: [UInt8]) -> [String] {
  var bits = [String]()
  for byte in bytes {
    for j in 0..<8 {
      let bit = (byte >> j) & 1
      bits.append(String(bit))
    }
  }
  return bits
}
