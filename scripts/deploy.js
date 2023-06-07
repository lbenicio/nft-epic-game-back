const main = async () => {
    const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");
    const gameContract = await gameContractFactory.deploy(
        ["Druid", "Sorcerer", "Paladin", "knight"],
        [
            "https://i.imgur.com/qSJr8qN.png",
            "https://i.imgur.com/wfZe6Pi.png",
            "https://i.imgur.com/iPQKyYC.png",
            "https://i.imgur.com/NtxXkET.png"
        ],
        [100, 100, 200, 300], // HP values
        [300, 300, 200, 300], // HP values
        [100, 100, 50, 25], // Attack damage values
        "Demon",
        "https://i.imgur.com/4et9GeB.gif",
        10000,
        10000,
        50    
    );
    await gameContract.deployed();
    console.log("Contrato implantado no endereço:", gameContract.address)
  };
  
  const runMain = async () => {
    try {
      await main();
      process.exit(0);
    } catch (error) {
      console.log(error);
      process.exit(1);
    }
  };
  
  runMain();
  