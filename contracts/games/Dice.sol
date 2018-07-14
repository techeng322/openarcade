pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../Util.sol";
import { DiceConnect as Connect } from "../.generated/DiceConnect.sol";


// Dice is a pretty contrived example to show how RNG reset works
library Dice {
    using SafeMath for uint256;

    struct State {
        uint roundsLeft;
        mapping(uint=>uint) score;
        bool resettingRng;
    }

    struct Action {
        // player can choose to roll or give up
        bool roll;
    }

    event LogRoll(uint pid, uint roll);

    /* Internal functions */

    function init(State storage state, Connect.Tools storage tools, uint playerCount)
        internal
        returns (uint)
    {
        state.roundsLeft = 2;
        // start the game with player 1 in control
        return 1;
    }

    function next(State storage state, Connect.Info storage info)
        internal view
        returns (uint)
    {
        return 1 + info.control % info.playerCount;
    }

    function update(State storage state, Connect.Tools storage tools, Connect.Info storage info, Connect.Input memory input)
        internal
    {
        // it's guaranteed that update will be executed when RNG is in ready state
        if (input.action.roll) {
            uint prevScore = state.score[input.pid];
            uint roll = 1 + tools.random.next() % 6;
            emit LogRoll(input.pid, roll);
            state.score[input.pid] = prevScore.add(roll);
            // reset the RNG so next time we'll get fresh randomness
            tools.random.reset();
        }
        // if we are at the last player in current round, go to next round
        if (input.pid == info.playerCount) {
            state.roundsLeft--;
        }
    }

    function legal(State storage state, Connect.Info storage info, Connect.Input memory input)
        internal view
        returns (bool)
    {
        // player can only play in his/her turn
        if (info.control != input.pid) {
            return false;
        }
        return true;
    }

    function terminal(State storage state, Connect.Info storage info)
        internal view
        returns (bool)
    {
        return state.roundsLeft == 0;
    }

    function goal(State storage state, Connect.Info storage info, uint pid)
        internal view
        returns (uint)
    {
        return state.score[pid];
    }

    function decodeAction(bytes s)
        internal pure
        returns (Action)
    {
        return Action({
            roll: s[31] == 1
        });
    }

    /* External functions */

    function encodeAction(bool play)
        external pure
        returns (bytes)
    {
        return abi.encode(play);
    }
}
