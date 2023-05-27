# Copyright 2022 Cartesi Pte. Ltd.
#
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use
# this file except in compliance with the License. You may obtain a copy of the
# License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

from os import environ
import logging
import requests
import json
import random
from eth_abi import decode_abi, encode_abi

logging.basicConfig(level="INFO")
logger = logging.getLogger(__name__)

rollup_server = environ["ROLLUP_HTTP_SERVER_URL"]

logger.info(f"HTTP rollup_server url is {rollup_server}")

def hex2str(hex):
    """
    Decodes a hex string into a regular string
    """
    return bytes.fromhex(hex[2:]).decode("utf-8")

def str2hex(str):
    """
    Encodes a string as a hex string
    """
    return "0x" + str.encode("utf-8").hex()

def post(endpoint, json):
    response = requests.post(f"{rollup_server}/{endpoint}", json=json)
    logger.info(f"Received {endpoint} status {response.status_code} body {response.content}")

def process_chainlink_input(binary):
    # decode payload
    btc_timestamp, btc_price, eth_timestamp, eth_price, link_timestamp, link_price = decode_abi(
        ['uint', 'int', 'uint', 'int', 'uint', 'int'],
        binary
    )

    # build notice
    notice = {
        "btc-timestamp": btc_timestamp,
        "btc-price (USD)": btc_price * 10**(-8),
        "ETH-timestamp": eth_timestamp,
        "ETH-price (USD)": eth_price * 10**(-8),
        "LINK-timestamp": link_timestamp,
        "LINK-price (USD)": link_price * 10**(-8)
    }

    return notice

def process_uniswap_input(binary):
    # decode payload
    (usdc_weth, usdc_weth_ts, usdc_reserves, weth0_reserves,
    uni_weth, uni_weth_ts, uni_reserves, weth1_reserves,
    zeta_weth, zeta_weth_ts, zeta_reserves, weth2_reserves) = decode_abi(
        [
            'uint', 'uint32', 'uint112', 'uint112',
            'uint', 'uint32', 'uint112', 'uint112',
            'uint', 'uint32', 'uint112', 'uint112'
        ],
        binary
    )

    # build notice
    notice = {
        "USDCxWETH-timestamp": usdc_weth_ts,
        "USDCxWETH": f"1:{usdc_weth}",
        "USDCxWETH-Reserves": f"{usdc_reserves}x{weth0_reserves}",
        "UNIxWETH-timestamp": uni_weth_ts,
        "UNIxWETH": f"1:{uni_weth}",
        "UNIxWETH-Reserves": f"{uni_reserves}x{weth1_reserves}",
        "ZETAxWETH-timestamp": zeta_weth_ts,
        "ZETAxWETH": f"1:{zeta_weth}",
        "ZETAxWETH-Reserves": f"{zeta_reserves}x{weth2_reserves}"
    }

    return notice

def handle_advance(data):
    logger.info(f"Received advance request data {data}")

    status = "accept"
    try:
        binary = bytes.fromhex(data["payload"][2:])
        notice = None

        try:
            notice = process_uniswap_input(binary)
        except:
            notice = process_chainlink_input(binary)

        post("notice", {"payload": str2hex(json.dumps(notice))})

    except Exception as e:
        status = "reject"
        post("report", {"payload": str2hex(str(e))})

    return status

def handle_inspect(data):
    logger.info(f"Received inspect request data {data}")
    logger.info("Adding report")

    post("report", {"payload": data["payload"]})
    return "accept"

handlers = {
    "advance_state": handle_advance,
    "inspect_state": handle_inspect,
}

finish = {"status": "accept"}
rollup_address = None

while True:
    logger.info("Sending finish")
    response = requests.post(rollup_server + "/finish", json=finish)
    logger.info(f"Received finish status {response.status_code}")
    if response.status_code == 202:
        logger.info("No pending rollup request, trying again")
    else:
        rollup_request = response.json()
        data = rollup_request["data"]
        if "metadata" in data:
            metadata = data["metadata"]
            if metadata["epoch_index"] == 0 and metadata["input_index"] == 0:
                rollup_address = metadata["msg_sender"]
                logger.info(f"Captured rollup address: {rollup_address}")
                continue
        handler = handlers[rollup_request["request_type"]]
        finish["status"] = handler(rollup_request["data"])
