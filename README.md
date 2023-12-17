<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->

<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

<!-- PROJECT LOGO -->
<br />

<h3 align="center">Exogenous Stablecoin</h3>

  <p align="center">
    This is a Decentralised Algorithmic Exogenous Stablecoin using chainlink price feeds to ensure coins can only be minted with enough collateral
    <br />
    <a href="https://github.com/achoudhury4927/foundry-adil-stablecoin"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/achoudhury4927/foundry-adil-stablecoin">View Demo</a>
    ·
    <a href="https://github.com/achoudhury4927/foundry-adil-stablecoin/issues">Report Bug</a>
    ·
    <a href="https://github.com/achoudhury4927/foundry-adil-stablecoin/issues">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->

## About The Project

### Built With

- Solidity
- Foundry

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

## Getting Started

To get a local copy up and running follow these simple example steps.

### Prerequisites

You will need foundry to install the packages and run tests. You can find out more here: https://book.getfoundry.sh/getting-started/installation. Make to run the makefile commands.

- foundry

  ```sh
  curl -L https://foundry.paradigm.xyz | bash
  ```

- foundryup

  ```sh
  foundryup
  ```

- make
  ```sh
  sudo apt-get install make
  ```

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/achoudhury4927/foundry-adil-erc721.git
   ```
2. Run Anvil
   ```sh
   make anvil
   ```
3. Deploy contracts on local Anvil chain
   ```sh
   make deploy
   ```
4. Run tests
   ```sh
   make test
   ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ROADMAP -->

## Roadmap

- [x] ERC20 Stablecoin
  - [x] Unit Tests
  - [ ] Integration Tests
- [x] Deposit Collateral
  - [x] Unit Tests
  - [x] Fuzz Tests
  - [ ] Integration Tests
- [x] Chainlink Oracle Pricefeeds
  - [x] Unit Tests
  - [x] Fuzz Tests
  - [ ] Integration Tests
- [x] Mint
  - [x] Unit Tests
  - [x] Fuzz Tests
  - [ ] Integration Tests
- [x] Burn
  - [x] Unit Tests
  - [ ] Fuzz Tests
  - [ ] Integration Tests
- [x] Liquidations
  - [x] Unit Tests
  - [ ] Fuzz Tests
  - [ ] Integration Tests
- [ ] Deploy Engine Script
- [ ] Deploy to Base L2

See the [open issues](https://github.com/achoudhury4927/foundry-adil-stablecoin/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- LICENSE -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

## Contact

Adil Choudhury - [@0xAdilc](https://twitter.com/0xAdilc) - contact@adilc.me

Project Link: [https://github.com/achoudhury4927/foundry-adil-stablecoin](https://github.com/achoudhury4927/foundry-adil-stablecoin)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[contributors-shield]: https://img.shields.io/github/contributors/achoudhury4927/foundry-adil-stablecoin.svg?style=for-the-badge
[contributors-url]: https://github.com/achoudhury4927/foundry-adil-stablecoin/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/achoudhury4927/foundry-adil-stablecoin.svg?style=for-the-badge
[forks-url]: https://github.com/achoudhury4927/foundry-adil-stablecoin/network/members
[stars-shield]: https://img.shields.io/github/stars/achoudhury4927/foundry-adil-stablecoin.svg?style=for-the-badge
[stars-url]: https://github.com/achoudhury4927/foundry-adil-stablecoin/stargazers
[issues-shield]: https://img.shields.io/github/issues/achoudhury4927/foundry-adil-stablecoin.svg?style=for-the-badge
[issues-url]: https://github.com/achoudhury4927/foundry-adil-stablecoin/issues
[license-shield]: https://img.shields.io/github/license/achoudhury4927/foundry-adil-stablecoin.svg?style=for-the-badge
[license-url]: https://github.com/achoudhury4927/foundry-adil-stablecoin/blob/master/LICENSE.txt
[product-screenshot]: images/screenshot.png
